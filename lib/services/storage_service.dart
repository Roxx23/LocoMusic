import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadSong(String filePath, String fileName) async {
    Reference ref = _storage.ref().child('songs/$fileName');
    await ref.putFile(File(filePath));
    String downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }
}
