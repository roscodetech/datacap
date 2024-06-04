import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/media_data.dart';

class UploadService {
  // Ensure Firebase is initialized before calling uploadMedia
  UploadService() {
    Firebase.initializeApp();
  }

  Future<void> uploadMedia(MediaData mediaData) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();

      // Determine the file extension based on the media type
      String fileExtension = mediaData.isVideo ? '.mp4' : '.jpg';
      final mediaRef = storageRef.child(
          'uploads/${mediaData.animalName}_${mediaData.timestamp.toIso8601String()}$fileExtension');

      // Use the File class from dart:io
      File file = File(mediaData.filePath);

      final uploadTask = mediaRef.putFile(file);

      // Listen for state changes, errors, and completion of the upload.
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        switch (snapshot.state) {
          case TaskState.running:
            print('Upload is running');
            break;
          case TaskState.paused:
            print('Upload is paused');
            break;
          case TaskState.success:
            print('Upload was successful');
            break;
          case TaskState.canceled:
            print('Upload was canceled');
            break;
          case TaskState.error:
            print('Upload failed');
            break;
        }
      });

      // Wait for the upload to complete.
      await uploadTask;

      final downloadUrl = await mediaRef.getDownloadURL();
      print('Upload successful, download URL: $downloadUrl');
    } catch (e) {
      print('Upload failed: $e');
    }
  }
}
