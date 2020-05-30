import 'dart:io';
import 'dart:math';
import 'GlobalConstants.dart';
import 'package:english_words/english_words.dart';

class FileCreator {
  void createFiles(String rootDirectory, int noOfFiles) {
    if (noOfFiles <= 1) {
      print('Inavlid number of files');
      return;
    }
    for (var i = 0; i < noOfFiles; i++) {
      final fileIdentifer =
          Random().nextInt(pow(10, GlobalConstants.FileNameSize)).toString();
      final fileName = '$fileIdentifer';

      var file = File('${Directory(rootDirectory).path}\\$fileName');
      print(file.path);
      final fileContents = generateRandomFileContent();
      print('writing to ${file.path}');
      file.writeAsString(fileContents);
    }
  }

  String generateRandomFileContent() {
    String result = '';
    for (int i = 0; i < GlobalConstants.FileSize; i++) {
      result += '${all[Random().nextInt(all.length)]} ';
    }
    return result;
  }
}

void usage() {
  print('Usage: FileCreator ROOT_DIRECTORY NUMBER_OF_FILES');
}

void main(List<String> arguments) async {
  if (arguments.length != 2) {
    usage();
    return;
  }

  final rootDirPath = arguments[0];
  final rootDirectory = Directory(rootDirPath);
  if (!await rootDirectory.exists()) {
    print('Invalid root directory ${rootDirectory.path}');
    return;
  }
  int noOfFiles;
  try {
    noOfFiles = int.parse(arguments[1]);
  } on FormatException {
    print('Invalid file number');
    return;
  }
  final fileCreator = FileCreator();
  fileCreator.createFiles(rootDirPath, noOfFiles);
}
