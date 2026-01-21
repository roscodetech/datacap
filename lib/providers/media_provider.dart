import 'package:flutter/material.dart';
import '../models/media_data.dart';

class MediaProvider with ChangeNotifier {
  final List<MediaData> _mediaList = [];
  bool _isLoading = false;
  String? _lastDatasetName;
  String? _lastClassLabel;

  List<MediaData> get mediaList => List.unmodifiable(_mediaList);
  bool get isLoading => _isLoading;
  String? get lastDatasetName => _lastDatasetName;
  String? get lastClassLabel => _lastClassLabel;

  List<MediaData> get pendingMedia =>
      _mediaList.where((m) => m.status == UploadStatus.pending).toList();

  List<MediaData> get uploadingMedia =>
      _mediaList.where((m) => m.status == UploadStatus.uploading).toList();

  List<MediaData> get completedMedia =>
      _mediaList.where((m) => m.status == UploadStatus.success).toList();

  List<MediaData> get failedMedia =>
      _mediaList.where((m) => m.status == UploadStatus.failed).toList();

  List<MediaData> get photos =>
      _mediaList.where((m) => m.mediaType == MediaType.photo).toList();

  List<MediaData> get videos =>
      _mediaList.where((m) => m.mediaType == MediaType.video).toList();

  int get pendingCount => pendingMedia.length;
  int get totalCount => _mediaList.length;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addMedia(MediaData mediaData) {
    _mediaList.add(mediaData);
    _lastDatasetName = mediaData.datasetName;
    _lastClassLabel = mediaData.classLabel;
    notifyListeners();
  }

  void removeMedia(String id) {
    _mediaList.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  void updateMediaStatus(String id, UploadStatus status, {double? progress, String? error}) {
    final index = _mediaList.indexWhere((m) => m.id == id);
    if (index != -1) {
      _mediaList[index] = _mediaList[index].copyWith(
        status: status,
        uploadProgress: progress,
        errorMessage: error,
      );
      notifyListeners();
    }
  }

  void clearCompleted() {
    _mediaList.removeWhere((m) => m.status == UploadStatus.success);
    notifyListeners();
  }

  void clearFailed() {
    _mediaList.removeWhere((m) => m.status == UploadStatus.failed);
    notifyListeners();
  }

  void clearAll() {
    _mediaList.clear();
    notifyListeners();
  }

  void retryFailed() {
    for (int i = 0; i < _mediaList.length; i++) {
      if (_mediaList[i].status == UploadStatus.failed) {
        _mediaList[i] = _mediaList[i].copyWith(
          status: UploadStatus.pending,
          uploadProgress: 0.0,
          errorMessage: null,
        );
      }
    }
    notifyListeners();
  }

  MediaData? getById(String id) {
    try {
      return _mediaList.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
