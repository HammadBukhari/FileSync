import 'dart:io';
import 'dart:math';
import 'package:watcher/watcher.dart';

import 'FileCreator.dart';

// NOT NEEDED
class FileShuffler {
  void editRandomFile(String rootDirPath) {
    final directoryFiles = Directory(rootDirPath).listSync();
    // Directory(rootDirPath).list().listen((data) => print(data.));
    // FileSystemEntity.
    DirectoryWatcher(rootDirPath).events.listen((change) {
      print('${change.type.toString()} ${change.path}');
    });
    final fileNumber = Random().nextInt(directoryFiles.length);
    Future.delayed(Duration(seconds: 3))
        .then((onValue) => editFile(File(directoryFiles[fileNumber].path)));
  }

  void editFile(File file) {
    print('Editing ${file.path}');
    file.writeAsString(FileCreator().generateRandomFileContent());
  }
}

void usage() {
  print('Usage: FileShuffler ROOT_DIRECTORY');
}

void main(List<String> arguments) async {
  if (arguments.length != 1) {
    usage();
    return;
  }

  final rootDirPath = arguments[0];
  final rootDirectory = Directory(rootDirPath);
  if (!await rootDirectory.exists()) {
    print('Invalid root directory ${rootDirectory.path}');
    return;
  }
  final fileShuffler = FileShuffler();
  fileShuffler.editRandomFile(rootDirPath);
}
