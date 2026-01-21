import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/media_data.dart';

class UploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // In-memory cache
  static List<StorageItem>? _cachedItems;
  static bool _cacheValid = false;

  // Invalidate cache (call after any modification)
  static void invalidateCache() {
    _cacheValid = false;
  }

  // Check if cache is valid
  static bool get hasCachedData => _cacheValid && _cachedItems != null;

  // Get cached items without fetching
  static List<StorageItem>? get cachedItems => _cachedItems;

  Future<String> uploadMedia(MediaData mediaData) async {
    print('🔥 Starting upload for: ${mediaData.storagePath}');
    final storageRef = _storage.ref();
    final mediaRef = storageRef.child(mediaData.storagePath);
    print('🔥 Storage ref created: ${mediaData.storagePath}');

    try {
      final UploadTask uploadTask;
      
      if (kIsWeb && mediaData.xFile != null) {
        print('🔥 Web upload - reading bytes from XFile');
        // On web, use XFile to read bytes
        final XFile xFile = mediaData.xFile as XFile;
        final bytes = await xFile.readAsBytes();
        print('🔥 Read ${bytes.length} bytes from XFile');
        uploadTask = mediaRef.putData(bytes);
        print('🔥 Upload task created with putData');
      } else if (!kIsWeb) {
        print('🔥 Mobile/Desktop upload - using File');
        // On mobile/desktop, use File
        final file = File(mediaData.filePath);
        if (!file.existsSync()) {
          throw Exception('File not found: ${mediaData.filePath}');
        }
        uploadTask = mediaRef.putFile(file);
      } else {
        throw Exception('No file available for upload');
      }

      print('🔥 Waiting for upload to complete...');
      await uploadTask;
      print('🔥 Upload completed!');
      final downloadUrl = await mediaRef.getDownloadURL();
      print('🔥 Download URL: $downloadUrl');
      invalidateCache(); // Invalidate cache after upload
      return downloadUrl;
    } catch (e) {
      print('❌ Upload failed: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> uploadMediaWithProgress(
    MediaData mediaData, {
    void Function(double progress)? onProgress,
  }) async {
    final storageRef = _storage.ref();
    final mediaRef = storageRef.child(mediaData.storagePath);

    try {
      final UploadTask uploadTask;
      
      if (kIsWeb && mediaData.xFile != null) {
        // On web, use XFile to read bytes
        final XFile xFile = mediaData.xFile as XFile;
        final bytes = await xFile.readAsBytes();
        uploadTask = mediaRef.putData(bytes);
      } else if (!kIsWeb) {
        // On mobile/desktop, use File
        final file = File(mediaData.filePath);
        if (!file.existsSync()) {
          throw Exception('File not found: ${mediaData.filePath}');
        }
        uploadTask = mediaRef.putFile(file);
      } else {
        throw Exception('No file available for upload');
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress?.call(progress);
        }
      });

      await uploadTask;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteMedia(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    await ref.delete();
    invalidateCache();
  }

  Future<List<StorageItem>> listAllMedia({
    String path = 'datasets',
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _cacheValid && _cachedItems != null) {
      print('📦 Using cached data (${_cachedItems!.length} items)');
      return _cachedItems!;
    }

    print('🔄 Fetching fresh data from Firebase Storage...');
    final List<StorageItem> items = [];
    await _listItemsRecursively(_storage.ref().child(path), items);
    // Sort by newest first
    items.sort((a, b) => b.timeCreated.compareTo(a.timeCreated));

    // Update cache
    _cachedItems = items;
    _cacheValid = true;
    print('📦 Cached ${items.length} items');

    return items;
  }

  Future<void> _listItemsRecursively(Reference ref, List<StorageItem> items) async {
    try {
      final result = await ref.listAll();

      // Add files
      for (final item in result.items) {
        try {
          final metadata = await item.getMetadata();
          final downloadUrl = await item.getDownloadURL();
          items.add(StorageItem(
            name: item.name,
            fullPath: item.fullPath,
            downloadUrl: downloadUrl,
            contentType: metadata.contentType ?? '',
            size: metadata.size ?? 0,
            timeCreated: metadata.timeCreated ?? DateTime.now(),
          ));
        } catch (e) {
          print('Error getting metadata for ${item.fullPath}: $e');
        }
      }

      // Recurse into folders
      for (final prefix in result.prefixes) {
        await _listItemsRecursively(prefix, items);
      }
    } catch (e) {
      print('Error listing items at ${ref.fullPath}: $e');
    }
  }

  Future<void> deleteByUrl(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    await ref.delete();
    invalidateCache();
  }

  // Delete all files in a path (for deleting datasets or classes)
  Future<int> deleteAllInPath(String path) async {
    int deletedCount = 0;
    final ref = _storage.ref().child(path);

    try {
      final result = await ref.listAll();

      // Delete all files
      for (final item in result.items) {
        try {
          await item.delete();
          deletedCount++;
        } catch (e) {
          print('Error deleting ${item.fullPath}: $e');
        }
      }

      // Recurse into subfolders
      for (final prefix in result.prefixes) {
        deletedCount += await _deleteAllInPathInternal(prefix.fullPath);
      }
    } catch (e) {
      print('Error listing items at $path: $e');
    }

    invalidateCache();
    return deletedCount;
  }

  // Internal method without cache invalidation for recursion
  Future<int> _deleteAllInPathInternal(String path) async {
    int deletedCount = 0;
    final ref = _storage.ref().child(path);

    try {
      final result = await ref.listAll();

      for (final item in result.items) {
        try {
          await item.delete();
          deletedCount++;
        } catch (e) {
          print('Error deleting ${item.fullPath}: $e');
        }
      }

      for (final prefix in result.prefixes) {
        deletedCount += await _deleteAllInPathInternal(prefix.fullPath);
      }
    } catch (e) {
      print('Error listing items at $path: $e');
    }

    return deletedCount;
  }

  // Rename/move a single file
  Future<void> renameFile(String oldPath, String newPath) async {
    final oldRef = _storage.ref().child(oldPath);
    final newRef = _storage.ref().child(newPath);

    // Download the file data
    final data = await oldRef.getData();
    if (data == null) throw Exception('Could not read file data');

    // Get metadata
    final metadata = await oldRef.getMetadata();

    // Upload to new location
    await newRef.putData(data, SettableMetadata(contentType: metadata.contentType));

    // Delete old file
    await oldRef.delete();
  }

  // Rename a dataset or class (moves all files)
  Future<int> renamePath(String oldBasePath, String newBasePath) async {
    final count = await _renamePathInternal(oldBasePath, newBasePath);
    invalidateCache();
    return count;
  }

  // Internal method without cache invalidation for recursion
  Future<int> _renamePathInternal(String oldBasePath, String newBasePath) async {
    int movedCount = 0;
    final ref = _storage.ref().child(oldBasePath);

    try {
      final result = await ref.listAll();

      // Move all files
      for (final item in result.items) {
        try {
          final relativePath = item.fullPath.substring(oldBasePath.length);
          final newPath = newBasePath + relativePath;
          await renameFile(item.fullPath, newPath);
          movedCount++;
        } catch (e) {
          print('Error moving ${item.fullPath}: $e');
        }
      }

      // Recurse into subfolders
      for (final prefix in result.prefixes) {
        final relativePath = prefix.fullPath.substring(oldBasePath.length);
        final newSubPath = newBasePath + relativePath;
        movedCount += await _renamePathInternal(prefix.fullPath, newSubPath);
      }
    } catch (e) {
      print('Error listing items at $oldBasePath: $e');
    }

    return movedCount;
  }
}

class StorageItem {
  final String name;
  final String fullPath;
  final String downloadUrl;
  final String contentType;
  final int size;
  final DateTime timeCreated;

  StorageItem({
    required this.name,
    required this.fullPath,
    required this.downloadUrl,
    required this.contentType,
    required this.size,
    required this.timeCreated,
  });

  bool get isVideo => contentType.startsWith('video/') ||
      name.endsWith('.webm') ||
      name.endsWith('.mp4');

  bool get isImage => contentType.startsWith('image/') ||
      name.endsWith('.png') ||
      name.endsWith('.jpg') ||
      name.endsWith('.jpeg');

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Parse dataset name from path: datasets/{datasetName}/{classLabel}/...
  String? get datasetName {
    final parts = fullPath.split('/');
    if (parts.length >= 2 && parts[0] == 'datasets') {
      return parts[1];
    }
    return null;
  }

  // Parse class label from path: datasets/{datasetName}/{classLabel}/...
  String? get classLabel {
    final parts = fullPath.split('/');
    if (parts.length >= 3 && parts[0] == 'datasets') {
      return parts[2];
    }
    return null;
  }
}

class DatasetInfo {
  final String name;
  final List<String> classes;
  final int photoCount;
  final int videoCount;

  DatasetInfo({
    required this.name,
    required this.classes,
    required this.photoCount,
    required this.videoCount,
  });

  int get totalCount => photoCount + videoCount;
}
