// import 'dart:convert';

// import 'package:dart_test/FileMeta.dart';

// class NetworkFile {
//   FileMeta meta;
//   String content;
//   NetworkFile({
//     this.meta,
//     this.content,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'meta': meta?.toMap(),
//       'content': content,
//     };
//   }

//   static NetworkFile fromMap(Map<String, dynamic> map) {
//     if (map == null) return null;
  
//     return NetworkFile(
//       meta: FileMeta.fromMap(map['meta']),
//       content: map['content'],
//     );
//   }

//   String toJson() => json.encode(toMap());

//   static NetworkFile fromJson(String source) => fromMap(json.decode(source));
// }
//  class FileSync {
// //   String fileName;
// //   String content;
// //   FileSync({
// //     this.fileName,
// //     this.content,
// //   });

// //   Map<String, dynamic> toMap() {
// //     return {
// //       'fileName': fileName,
// //       'content': content,
// //     };
// //   }

// //   static FileSync fromMap(Map<String, dynamic> map) {
// //     if (map == null) return null;

// //     return FileSync(
// //       fileName: map['fileName'],
// //       content: map['content'],
// //     );
// //   }

// //   String toJson() => json.encode(toMap());

// //   static FileSync fromJson(String source) => fromMap(json.decode(source));

// //   @override
// //   String toString() => 'FileSync(fileName: $fileName, content: $content)';
// // }
