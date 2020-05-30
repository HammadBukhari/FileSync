import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:dart_test/NodeInfo.dart';
import 'package:path/path.dart';

enum Protocol { timestamp, vector }

class ServerMeta {
  int noOfFiles = 0;
  int Id;
  List<NodeInfo> clients;

  Protocol protocol = Protocol.vector;
  HashMap<String, HashMap<String, int>> filesTimestamp =
      HashMap<String, HashMap<String, int>>();
  HashMap<String, HashMap<String, bool>> clientsModifiedBits =
      HashMap<String, HashMap<String, bool>>();
  HashMap<String, String> files;
  String rootDirPath;

  ServerMeta(String rootDirPath,
      {this.Id,
      this.files,
      this.noOfFiles,
      this.protocol,
      this.filesTimestamp}) {
    this.rootDirPath = rootDirPath;
    if (rootDirPath != null) {
      noOfFiles = 0;

      protocol ??= Protocol.vector;
      filesTimestamp ??= HashMap<String, HashMap<String, int>>();
      clientsModifiedBits ??= HashMap<String, HashMap<String, bool>>();

      files = HashMap<String, String>();
      Directory(rootDirPath).listSync().forEach((file) {
        if (path.basename(file.path) != '$Id.meta') {
          noOfFiles++;
          files.putIfAbsent(
              file.path, () => File(file.path).readAsStringSync());
        }
      });
      // final value = HashMap<String, int>.from(
      //   files.map(
      //     (key, value) {
      //       return MapEntry<String, int>(
      //           key, DateTime.now().millisecondsSinceEpoch);
      //     },
      //   ),
      // );
      // final bitsValue = HashMap<String, bool>.from(
      //   files.map(
      //     (key, value) {
      //       return MapEntry<String, bool>(key, false);
      //     },
      //   ),
      // );
      // clientsModifiedBits.putIfAbsent(Id.toString(), () => bitsValue);
      // filesTimestamp.putIfAbsent('54', () => value);
      writeJson();
    }
  }

  void addNewClient(NodeInfo clientInfo, ServerMeta clientMeta) {
    clientsModifiedBits.putIfAbsent('${clientInfo.id}', () {
      return HashMap<String, bool>.from(files.map((key, value) {
        return MapEntry<String, bool>(key, true);
      }));
    });
    writeJson();
  }

  void writeJson() {
    File(path.join(rootDirPath, '$Id.meta'))
        .writeAsStringSync(jsonEncode(toMap()));
  }

  Map<String, dynamic> toMap() {
    return {
      'noOfFiles': noOfFiles,
      'Id': Id,
      'protocol': protocol.index,
      'files': files,
      'filesTimestamp': Map<String, dynamic>.from(filesTimestamp),
      'clientsModifiedBits': Map<String, dynamic>.from(clientsModifiedBits),
    };
  }

  void writeClientMetaJson() {
    final json = {
      'clients': clients?.map((x) => x?.toMap())?.toList(),
    };
    File(join(rootDirPath, '${Id}.clientmeta'))
        .writeAsStringSync(jsonEncode(json));
  }

  static ServerMeta fromMap(
    Map<String, dynamic> map,
    String rootDir,
  ) {
    if (map == null) return null;
    final HashMap files = HashMap<String, String>.from(map['files']);

    final timestamp = HashMap<String, dynamic>.from(map['filesTimestamp']);
    final ft = HashMap<String, HashMap<String, int>>();
    timestamp.forEach((key, value) {
      ft.putIfAbsent(key, () => HashMap<String, int>.from(value));
    });

    final bits = HashMap<String, dynamic>.from(map['clientsModifiedBits']);
    final b = HashMap<String, HashMap<String, bool>>();
    bits.forEach((key, value) {
      b.putIfAbsent(key, () => HashMap<String, bool>.from(value));
    });

    print('Meta exists');
    final repo = ServerMeta(null,
        noOfFiles: map['noOfFiles'],
        Id: map['Id'],
        protocol: Protocol.values[map['protocol']],
        files: files,
        filesTimestamp: ft);
    repo.filesTimestamp.forEach((key, value) {
      print('$key $value');
    });
    repo.rootDirPath = rootDir;
    return repo;
  }

  String toJson() => json.encode(toMap());

  static ServerMeta fromJson(
    String source,
    String rootDir,
  ) =>
      fromMap(json.decode(source), rootDir);

  @override
  String toString() {
    return 'ServerRepo(noOfFiles: $noOfFiles, Id: $Id, protocol: $protocol, files: $files)';
  }
}
