import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

class FileMeta {
  bool remoteChange = false;
  int ownerClientId;
  String fileName;
  Map<String, bool> modbits;
  Map<String, int> timestamps;
  Map<String, int> vectors;
  FileMeta({
    this.remoteChange,
    this.ownerClientId,
    this.fileName,
    this.modbits,
    this.timestamps,
    this.vectors,
  });
  void setRemoteChange(String rootDir, bool value) {
    remoteChange = value;
    writeMetaToDisk(rootDir);
  }

  void writeMetaToDisk(String rootDir) {
    File(join(rootDir, '$fileName.meta'))
        .writeAsStringSync(jsonEncode(toMap()));
  }

  Map<String, dynamic> toMap() {
    return {
      'remoteChange': remoteChange,
      'ownerClientId': ownerClientId,
      'fileName': fileName,
      'modbits': modbits,
      'timestamps': timestamps,
      'vectors': vectors,
    };
  }

  static FileMeta fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return FileMeta(
      remoteChange: map['remoteChange'],
      ownerClientId: map['ownerClientId'],
      fileName: map['fileName'],
      modbits: Map<String, bool>.from(map['modbits']),
      timestamps: Map<String, int>.from(map['timestamps']),
      vectors: Map<String, int>.from(map['vectors']),
    );
  }

  String toJson() => json.encode(toMap());

  static FileMeta fromJson(String source) => fromMap(json.decode(source));
}
