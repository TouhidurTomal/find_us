import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  Future<String> getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> getLocalFile(String fileName) async {
    final path = await getLocalPath();
    return File('$path/$fileName');
  }

  Future<void> saveFile(File file) async {
    final fileName = file.path.split('/').last; // Extract file name from path
    final localFile = await getLocalFile(fileName);
    await file.copy(localFile.path);
  }

  Future<void> deleteFile(String fileName) async {
    final localFile = await getLocalFile(fileName);
    if (await localFile.exists()) {
      await localFile.delete();
    }
  }

  Future<bool> fileExists(String fileName) async {
    final localFile = await getLocalFile(fileName);
    return await localFile.exists();
  }
}
