import 'dart:io';

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

  /// Uploads a file and returns its Firebase Storage path.
  Future<String> uploadFile({
    required File file,
    required String storagePath,
    required String contentType,
    int maximumFileSizeBytes = 10 * 1024 * 1024,
  }) async {
    final cleanPath = storagePath.trim();

    if (cleanPath.isEmpty) {
      throw ArgumentError('The storage path is empty');
    }

    if (!await file.exists()) {
      throw ArgumentError('The selected file does not exist');
    }

    if (await file.length() > maximumFileSizeBytes) {
      final maximumFileSizeMb = maximumFileSizeBytes ~/ (1024 * 1024);
      throw ArgumentError(
        'The selected file must be smaller than $maximumFileSizeMb MB',
      );
    }

    try {
      debugPrint('Uploading file to: $cleanPath');

      final storageReference = _storage.ref(cleanPath);
      final metadata = SettableMetadata(contentType: contentType);

      final uploadSnapshot = await storageReference.putFile(file, metadata);

      debugPrint(
        'Upload completed: '
        '${uploadSnapshot.bytesTransferred} bytes uploaded',
      );

      // Return the Storage path to save in Firestore.
      return storageReference.fullPath;
    } on FirebaseException catch (error) {
      debugPrint('Storage upload error code: ${error.code}');
      debugPrint('Storage upload error message: ${error.message}');
      rethrow;
    }
  }
}
