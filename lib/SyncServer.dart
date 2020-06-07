import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

import 'package:dart_test/FileMeta.dart';
import 'package:dart_test/FileServer.dart';
import 'package:dart_test/ServerRepo.dart';
import 'NetworkMessage.dart';
import 'NodeInfo.dart';

FileServer repo;

class ClientHandler {
  String rootDirPath;
  int id;
  List<NodeInfo> clients;
  ClientHandler({
    this.rootDirPath,
    this.id,
    this.clients,
  }) {
    // if [clients] is not provided through paramter
    // start with empty list
    clients ??= [];
  }
  NodeInfo getNodeInfoById(int toFind) =>
      clients.where((node) => node.id == toFind).first;
  void writeToDisk() {
    File(join(rootDirPath, '${id}.clientmeta')).writeAsStringSync(toJson());
  }

  Map<String, dynamic> toMap() {
    return {
      'rootDirPath': rootDirPath,
      'id': id,
      'clients': clients?.map((x) => x?.toMap())?.toList(),
    };
  }

  static ClientHandler fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return ClientHandler(
      rootDirPath: map['rootDirPath'],
      id: map['id'],
      clients:
          List<NodeInfo>.from(map['clients']?.map((x) => NodeInfo.fromMap(x))),
    );
  }

  void addNewClient(NodeInfo client) {
    print('clients = $clients');
    final searchClientLength =
        clients.where((node) => node.id == client.id).length;
    if (searchClientLength == 0) {
      // client doesnt already exist, add it
      clients.add(client);
      // add this client to already existing files
      repo.addNewClientToExistingFiles(client.id);
      writeToDisk();
    } else {
      print('client already registered');
    }
  }

  String toJson() => json.encode(toMap());

  static ClientHandler fromJson(String source) => fromMap(json.decode(source));
}

class SyncServer {
  String rootDirPath;
  Protocol protocol;
  int port;
  int clientId;
  ClientHandler clientHandler;
  String serverHostName;
  SyncServer({this.rootDirPath, this.port, this.clientId, this.protocol});

  void handleNewMeta(FileMeta fileMeta, NodeInfo sender) {
    // add the client to [clienthandler] if not already
    clientHandler.addNewClient(sender);
    // first check if meta contain my server id
    // if it doesnt contain the id, we are getting
    // file for the first time
    final file = File(join(rootDirPath, fileMeta.fileName));
    if (file.existsSync()) {
      print('file exists');
      inspectExistingFile(fileMeta, file, sender);
    } else {
      print('file does not exists');
      // request this file from client
      requestFileFromRemoteServer(fileMeta, sender, true);
    }
  }

  bool checkUpdateOrder(FileMeta remoteServerMeta, NodeInfo remoteServer) {
    // check the update order according to [protocol]
    // and decide whether to apply the update or not
    final serverMeta = repo
        .getAllMeta()
        .where((meta) => meta.fileName == remoteServerMeta.fileName)
        .first;
    if (protocol == Protocol.timestamp) {
      // check if file my timestamp is greater then [remoteServer] timestamp
      final serverTimestamp = serverMeta.timestamps[clientId.toString()];
      final remoteServerTimestamp =
          remoteServerMeta.timestamps[remoteServer.id.toString()];
      if (serverTimestamp > remoteServerTimestamp) {
        // we already have latest file, ignore this update
        print('Ignored by timestamp');
        return false;
      } else if (serverTimestamp == remoteServerTimestamp) {
        //conflict
        print('conflict in timestamp');
        // fallback to lower id wins method
        return !(clientId < remoteServer.id);
      } else {
        return true;
      }
    } else {
      // vector method
      bool isAllSmaller = false;
      bool isAllLarger = false;
      bool isConflictOcurred = false;
      serverMeta.vectors.forEach((node, value) {
        if (value <= remoteServerMeta.vectors[node]) {
          if (isAllLarger) isConflictOcurred = true;
          isAllSmaller = true;
        } else if (value >= remoteServerMeta.vectors[node]) {
          if (isAllSmaller) isConflictOcurred = true;
          isAllLarger = true;
        }
      });
      if (isConflictOcurred) {
        //fall back to lower id wins method
        print('conflict in vector');
        return !(clientId < remoteServer.id);
      } else {
        return isAllSmaller;
      }
    }
  }

  void inspectExistingFile(
      FileMeta fileMeta, File file, NodeInfo remoteServer) async {
    if (fileMeta.modbits[clientId.toString()] != null && fileMeta.modbits[clientId.toString()] &&
        checkUpdateOrder(fileMeta, remoteServer)) {
      // if the sender made any change since last fetch

      requestFileFromRemoteServer(fileMeta, remoteServer, false);
    } else {
      print('file already updated');
    }
  }

  NodeInfo getMyInfo() {
    return NodeInfo(
      hostname: serverHostName,
      id: clientId,
      port: port,
    );
  }

  void requestFileFromRemoteServer(
      FileMeta fileMeta, NodeInfo remoteServer, bool isNewFile) async {
    final requestMessage = NetworkMessage(
      senderInfo: getMyInfo(),
      type: NetworkMessageType.fileRequest,
      payload: fileMeta,
    );
    HttpClientRequest request =
        await HttpClient().post(remoteServer.hostname, remoteServer.port, '')
          ..headers.contentType = ContentType.json
          ..write(requestMessage.toJson());
    HttpClientResponse response = await request.close();
    await utf8.decoder.bind(response /*5*/).forEach((element) {
      repo.addNewFile(remoteServer, fileMeta, element, isNewFile);
    });
  }

  void initRepo() {
    repo = FileServer(rootDirPath, clientId);
  }

  void initServer() async {
    serverHostName =
        (await NetworkInterface.list()).last.addresses.first.address;
    print('Hostname: $serverHostName');
    var server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print(
        'Starting  server at ${server.address.address}:${port} using ${protocol == Protocol.timestamp ? 'Timestamp' : 'Vector'} protocol');
    await for (var req in server) {
      ContentType contentType = req.headers.contentType;
      HttpResponse response = req.response;
      if (req.method == 'POST' && contentType?.mimeType == 'application/json') {
        print('New request');
        String content = await utf8.decoder.bind(req).join();
        NetworkMessage networkMessage = NetworkMessage.fromJson(content);
        if (networkMessage.type == NetworkMessageType.connectionRequest) {
          final payload = networkMessage.payload as FileMeta;
          print(payload.fileName);
          handleNewMeta(payload, networkMessage.senderInfo);
        } else if (networkMessage.type ==
            NetworkMessageType.connectionRequestResponse) {
          // addNewClient(networkMessage.senderMeta, networkMessage.senderInfo);
        } else if (networkMessage.type == NetworkMessageType.fileRequest) {
          final meta = networkMessage.payload as FileMeta;
          final requestedFile = File(join(rootDirPath, meta.fileName));
          if (requestedFile.existsSync()) {
            repo.resetModBit(meta.fileName, networkMessage.senderInfo.id);
            response.write(requestedFile.readAsStringSync());
          } else {
            print(
                "File ${meta.fileName} requested by ${networkMessage.senderInfo.hostname}:${networkMessage.senderInfo.port} is not available");
          }
          // applyChange(
          //     networkMessage.senderInfo, networkMessage.payload as FileSync);
        } else if (networkMessage.type == NetworkMessageType.sendInvitation) {
          // check if the server need this file (order updates)

        }
        // } catch (e) {
        //   response
        //     ..statusCode = HttpStatus.internalServerError
        //     ..write('Exception: $e.');
        // }
      } else {
        response
          ..statusCode = HttpStatus.methodNotAllowed
          ..write('Unsupported request: ${req.method}.');
      }
      await response.close();
    }
  }

  void sendFileUpdates(List<String> clientsToSend, String fileName) async {
    final fileMeta =
        File(join(rootDirPath, '$fileName.meta')).readAsStringSync();
    clientsToSend.forEach((client) async {
      NodeInfo clientInfo = clientHandler.getNodeInfoById(int.parse(client));
      final requestMessage = NetworkMessage(
        senderInfo: getMyInfo(),
        type: NetworkMessageType.connectionRequest,
        payload: fileMeta,
      );
      HttpClientRequest request =
          await HttpClient().post(clientInfo.hostname, clientInfo.port, "")
            ..headers.contentType = ContentType.json
            ..write(requestMessage.toJson());
      HttpClientResponse response = await request.close();
      await utf8.decoder.bind(response /*5*/).forEach((element) {
        print(element);
      });
    });
  }

  void initWatcher() async {
    DirectoryWatcher(rootDirPath).events.listen((fileChange) {
      print('New file change');
      if (fileChange.path.endsWith('clientmeta')) return;
      if (fileChange.path.endsWith('meta')) {
        // change in meta file
        // check if modified bit is true
        // get the actual file name by removing .meta
        final fileName =
            fileChange.path.substring(0, fileChange.path.length - 5);
        final actualFile = File(fileName);
        final clientsToSendUpdate = repo.getClientsWithSetModBit(fileName);
        if (clientsToSendUpdate != null) {
          sendFileUpdates(clientsToSendUpdate, fileName);
        }
        return;
      }
      final changedFile = File(fileChange.path);
      final changedFileMeta = File('${fileChange.path}.meta');
      if (!changedFileMeta.existsSync()) return;
      final changedFileMetaContent =
          FileMeta.fromJson(changedFileMeta.readAsStringSync());
      // check if its a locally change
      if (!changedFileMetaContent.remoteChange) {
        // change all modbits to true
        repo.processLocalChange(changedFileMetaContent.fileName);
      } else {
        repo.resetRemoteChangeBit(changedFileMetaContent.fileName);
      }
    });
  }

  void initClientHandler() {
    final clientMetaFile = File(join(rootDirPath, '$clientId.clientmeta'));
    if (clientMetaFile.existsSync()) {
      print('Clients registered:');
      clientHandler = ClientHandler.fromJson(clientMetaFile.readAsStringSync());
      clientHandler.clients.forEach((f) => print('clientId = ${f.id}'));
    } else {
      clientHandler = ClientHandler(
        id: clientId,
        rootDirPath: rootDirPath,
      );
    }
  }

  Future<void> init() async {
    initRepo();
    initClientHandler();
    initServer();
    initWatcher();
  }
}

void usage() {
  print('Usage: SyncServer ROOT_DIRECTORY PORT ID PROTOCOL');
}

void main(List<String> arguments) async {
  if (arguments.length != 4) {
    usage();
    return;
  }

  final rootDirPath = arguments[0];
  final rootDirectory = Directory(rootDirPath);
  if (!await rootDirectory.exists()) {
    print('Invalid root directory ${rootDirectory.path}');
    return;
  }
  int port;
  try {
    port = int.parse(arguments[1]);
  } on FormatException {
    print('Invalid port number');
    return;
  }
  int id;
  try {
    id = int.parse(arguments[2]);
  } on FormatException {
    print('Invalid client id');
    return;
  }
  int protocol;
  try {
    protocol = int.parse(arguments[3]);
    if (protocol < 1 || protocol > 2) {
      print('Protocol can either be 1(timestamp) or 2(vector)');
      return;
    }
  } on FormatException {
    print('Protocol can either be 1(timestamp) or 2(vector)');
    return;
  }

  final syncServer = SyncServer(
      port: port,
      rootDirPath: rootDirPath,
      clientId: id,
      protocol: Protocol.values[protocol - 1]);
  await syncServer.init();
}
