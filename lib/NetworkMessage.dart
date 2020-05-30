import 'dart:convert';

import 'package:dart_test/FileMeta.dart';
import 'package:dart_test/NodeInfo.dart';
import 'package:dart_test/ServerRepo.dart';

import 'FileSync.dart';

enum NetworkMessageType {
  connectionRequest,
  connectionRequestResponse,
  fileResponse,
  fileRequest,
  sendInvitation,
}

// class ConnectionRequestMessage {
//   FileMeta fileMeta;
//   String fileContent;
//   ConnectionRequestMessage({
//     this.fileMeta,
//     this.fileContent,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'fileMeta': fileMeta?.toMap(),
//       'fileContent': fileContent,
//     };
//   }

//   static ConnectionRequestMessage fromMap(Map<String, dynamic> map) {
//     if (map == null) return null;

//     return ConnectionRequestMessage(
//       fileMeta: FileMeta.fromMap(map['fileMeta']),
//       fileContent: map['fileContent'],
//     );
//   }

//   String toJson() => json.encode(toMap());

//   static ConnectionRequestMessage fromJson(String source) =>
//       fromMap(json.decode(source));
// }

class NetworkMessage {
  NetworkMessageType type;
  NodeInfo senderInfo;
  dynamic payload;
  NetworkMessage({
    this.type,
    this.senderInfo,
    this.payload,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'senderInfo': senderInfo?.toMap(),
      'payload': payload,
    };
  }

  static NetworkMessage fromMap(Map<String, dynamic> map, {String rootDir}) {
    if (map == null) return null;

    NetworkMessageType type = NetworkMessageType.values[map['type']];
    dynamic payload;
    if (type == NetworkMessageType.fileResponse) {
      payload = map['payload'];
    } else if (type == NetworkMessageType.connectionRequest ||
        type == NetworkMessageType.connectionRequestResponse ||
        type == NetworkMessageType.fileRequest ||
        type == NetworkMessageType.sendInvitation) {
      payload = FileMeta.fromJson(map['payload']);
    }
    return NetworkMessage(
        type: type,
        senderInfo: NodeInfo.fromMap(map['senderInfo']),
        payload: payload);
  }

  String toJson() => json.encode(toMap());

  static NetworkMessage fromJson(String source, {String rootDir}) =>
      fromMap(json.decode(source), rootDir: rootDir);
}
