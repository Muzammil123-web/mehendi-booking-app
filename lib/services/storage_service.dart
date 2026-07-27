import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Uploads a local file (picked from the phone's gallery/camera) to Firebase
/// Storage and returns a public download URL to save on the Firestore doc.
class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadWorkPostFile(File file, {required bool isVideo}) async {
    final ext = isVideo ? 'mp4' : 'jpg';
    final ref = _storage.ref('work_posts/${const Uuid().v4()}.$ext');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }
}
