import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> getDownloadUrl(String iconPath) async {
    final cleanPath = iconPath.trim();

    if (cleanPath.isEmpty) {
      throw ArgumentError('The icon path is empty');
    }

    try {
      debugPrint('Loading Storage file: $cleanPath');

      final storageReference = _storage.ref(cleanPath);
      final downloadUrl = await storageReference.getDownloadURL();

      debugPrint('Download URL received: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (error) {
      debugPrint('Storage error code: ${error.code}');
      debugPrint('Storage error message: ${error.message}');
      rethrow;
    }
  }
}