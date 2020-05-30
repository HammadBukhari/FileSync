import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

import 'package:dart_test/NetworkMessage.dart';
import 'package:dart_test/NodeInfo.dart';
import 'package:dart_test/ServerRepo.dart';

import 'FileMeta.dart';

class connectToServer {
  NetworkMessageType type;
  String rootDirPath;
  int serverPort;
  String serverHostName;
  int clientId;
  int serverId;
  String clientHostName;
  int clientPort;
  connectToServer({
    this.rootDirPath,
    this.serverPort,
    this.serverHostName,
    this.clientId,
    this.clientHostName,
    this.clientPort,
    this.serverId,
    this.type,
  });

  Future<void> init() async {
    Directory(rootDirPath).listSync().forEach((f) async {
      final file = File(f.path);
      if (f.path.endsWith('.meta')) {
        type ??= NetworkMessageType.connectionRequest;
        // if (type == null) type = NetworkMessageType.connectionRequest;
        
        final networkMessage = NetworkMessage(
          senderInfo: NodeInfo(
              hostname: clientHostName, id: clientId, port: clientPort),
          type: type,
          payload: FileMeta.fromJson(file.readAsStringSync()),
        );
        HttpClientRequest request =
            await HttpClient().post(serverHostName, serverPort, "")
              ..headers.contentType = ContentType.json
              ..write(networkMessage.toJson());
        HttpClientResponse response = await request.close();
        await utf8.decoder.bind(response /*5*/).forEach((element) {
          print(element);
        });
      }
    });
  }
}

void usage() {
  print(
      'Usage: SyncClient ROOT_DIRECTORY CLIENT_ID  CLIENT_HOST_NAME CLIENT_PORT SERVER_ID SERVER_HOST_NAME SERVER_PORT');
}

void main(List<String> arguments) async {
  if (arguments.length != 7) {
    usage();
    return;
  }
  // root dir
  final rootDirPath = arguments[0];
  final rootDirectory = Directory(rootDirPath);
  if (!await rootDirectory.exists()) {
    print('Invalid root directory ${rootDirectory.path}');
    return;
  }
  int clientId;
  try {
    clientId = int.parse(arguments[1]);
  } on FormatException {
    print('Invalid client ID');
    return;
  }
  final clientHostName = arguments[2];

  int clientPort;

  try {
    clientPort = int.parse(arguments[3]);
  } on FormatException {
    print('Invalid client port');
    return;
  }
  int serverId;
  try {
    serverId = int.parse(arguments[4]);
  } on FormatException {
    print('Invalid server ID');
    return;
  }
  final serverHostName = arguments[5];
  int serverPort;
  try {
    serverPort = int.parse(arguments[6]);
  } on FormatException {
    print('Invalid server port');
    return;
  }
  final syncServer = connectToServer(
    rootDirPath: rootDirPath,
    clientHostName: clientHostName,
    clientId: clientId,
    clientPort: clientPort,
    serverHostName: serverHostName,
    serverPort: serverPort,
    serverId: serverId,
  );
  await syncServer.init();
}
