import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

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
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
