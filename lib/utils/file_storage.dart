import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/user_data.json');
  }

  Future<Map<String, dynamic>> readData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        return jsonDecode(contents);
      }
    } catch (e) {
      // TODO
    }
    return {};
  }

  Future<File> writeData(Map<String, dynamic> data) async {
    final file = await _localFile;
    return file.writeAsString(jsonEncode(data));
  }
}
