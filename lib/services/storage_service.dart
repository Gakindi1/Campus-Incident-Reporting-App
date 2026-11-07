import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads and deletes incident photos in Firebase Storage.
class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads [file] to `incidents/{uid}/{incidentId}/{timestamp}.jpg` and
  /// returns the storage path and public download URL.
  ///
  /// The owner's UID is part of the path so storage rules can restrict writes
  /// to the reporter's own folder.
  Future<({String path, String url})> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    final path =
        'incidents/$uid/$incidentId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref(path);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return (path: path, url: await ref.getDownloadURL());
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      // Already gone is fine: the goal is that the file no longer exists.
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
