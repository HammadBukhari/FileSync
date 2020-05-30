import 'dart:io';

import 'package:dart_test/FileMeta.dart';
import 'package:path/path.dart';

import 'NodeInfo.dart';

class FileServer {
  String rootDirPath;
  List<File> files;
  int id;
  List<FileMeta> filesMeta;
  List<FileMeta> getAllMeta() {
    final result = <FileMeta>[];
    Directory(rootDirPath).listSync().forEach((file) {
      if (file.path.endsWith('.meta')) {
        result.add(FileMeta.fromJson(File(file.path).readAsStringSync()));
        
      }
    });
    return result;
  }

  FileServer(String rootDirPath, int id) {
    this.rootDirPath = rootDirPath;
    this.id = id;
    files = List<File>();
    filesMeta = List<FileMeta>();
    Directory(rootDirPath).listSync().forEach((f) {
      if (!f.path.endsWith("meta")) {
        files.add(File(f.path));
        //check if file meta exists
        final metaFile = File(join('${f.path}.meta'));
        if (metaFile.existsSync()) {
          filesMeta.add(FileMeta.fromJson(metaFile.readAsStringSync()));
        } else {
          //create new file with 0 modbit

          final meta = FileMeta(
            remoteChange: false,
            ownerClientId: id,
            fileName: basename(f.path),
            modbits: <String, bool>{id.toString(): false},
            timestamps: <String, int>{
              id.toString(): DateTime.now().millisecondsSinceEpoch
            },
            vectors: <String, int>{id.toString(): 0},
          )..writeMetaToDisk(rootDirPath);
          filesMeta.add(meta);
        }
      }
    });
  }
  List<String> getClientsWithSetModBit(String fileName) {
    final result = <String>[];
    final metaIteratable =
        getAllMeta().where((meta) => meta.fileName == basename(fileName));

    if (metaIteratable.isNotEmpty) {
      final meta = metaIteratable.first;
      meta.modbits.forEach((clientId, modbit) {
        if (modbit && clientId != id.toString()) result.add(clientId);
      });
    } else {
      print('$fileName meta doesnt exists');
      return null;
    }

    return result;
  }

  void resetRemoteChangeBit(String fileName) {
    print('resetting remote change bit for file $fileName');
    final meta = getAllMeta().where((meta) => meta.fileName == fileName).first;
    if (meta != null) {
      meta.setRemoteChange(rootDirPath, false);
    } else {
      print(
          'could not reset remote change bit for file $fileName with id:${id}');
    }
  }

  void resetModBit(String fileName, int id) {
    print('resetting mod bit for file $fileName with id:${id}');
    final meta = getAllMeta().where((meta) => meta.fileName == fileName).first;
    if (meta != null) {
      print('prev value = ${meta.modbits[id.toString()]}');
      meta.modbits[id.toString()] = false;
      meta.writeMetaToDisk(rootDirPath);
    } else {
      print('could not reset bit for file $fileName with id:${id}');
    }
  }

  void addNewClientToExistingFiles(int clientId) {
    getAllMeta().forEach((fileMeta) {
      print('Updating file ${fileMeta.fileName} for $clientId');
      fileMeta.modbits.putIfAbsent(clientId.toString(), () => false);
      fileMeta.timestamps.putIfAbsent(
          clientId.toString(), () => fileMeta.timestamps[id.toString()]);
      fileMeta.vectors.putIfAbsent(
          clientId.toString(), () => fileMeta.vectors[id.toString()]);
      fileMeta.setRemoteChange(rootDirPath, true);
      fileMeta.writeMetaToDisk(rootDirPath);
    });
  }

  void addNewFile(NodeInfo sender, FileMeta fileMeta, String content,
      bool isNewFile) async {
    if (isNewFile) {
      fileMeta.modbits[id.toString()] = false;
      fileMeta.timestamps[id.toString()] =
          fileMeta.timestamps[sender.id.toString()];
      fileMeta.vectors[id.toString()] = fileMeta.vectors[sender.id.toString()];
    }

    // write .meta file before actual file
    // as FileWatcher will through exception for a file
    // without its .meta file
    // if (isNewFile) {
    // getAllMeta().add(fileMeta);
    // } else {
    //   //remove the existing meta and write the new one
    //   getAllMeta().removeWhere(
    //       (existingMeta) => existingMeta.fileName == fileMeta.fileName);
    //   getAllMeta().add(fileMeta);
    // }
    if (!isNewFile) {
      fileMeta.modbits[sender.id.toString()] = false;
    }
    fileMeta.setRemoteChange(rootDirPath, true);
    // await File(join(rootDirPath, '${fileMeta.fileName}.meta'))
    //     .writeAsString(fileMeta.toJson());
    File(join(rootDirPath, fileMeta.fileName)).writeAsStringSync(content);
  }

  void processLocalChange(String fileName) {
    final meta = getAllMeta().where((meta) => meta.fileName == fileName).first;
    if (meta != null) {
      meta.modbits.forEach((id, modbit) {
        print('setting $fileName $id mod bit to true');
        meta.modbits[id.toString()] = true;
      });
      meta.vectors[id.toString()] = meta.vectors[id.toString()] + 1;
      meta.timestamps[id.toString()] = DateTime.now().millisecondsSinceEpoch;
      meta.writeMetaToDisk(rootDirPath);
    } else {
      print('could not process local change for file $fileName');
    }
  }
}
