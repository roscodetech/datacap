enum UploadStatus {
  pending,
  uploading,
  success,
  failed,
}

enum MediaType {
  photo,
  video,
}

class MediaData {
  final String id;
  final String filePath;
  final String classLabel;
  final String datasetName;
  final DateTime timestamp;
  final MediaType mediaType;
  final UploadStatus status;
  final double uploadProgress;
  final String? errorMessage;
  final dynamic xFile; // XFile from image_picker for web support

  MediaData({
    String? id,
    required this.filePath,
    required this.classLabel,
    required this.datasetName,
    DateTime? timestamp,
    required this.mediaType,
    this.status = UploadStatus.pending,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.xFile,
  })  : id = id ?? '${DateTime.now().millisecondsSinceEpoch}_${filePath.hashCode}',
        timestamp = timestamp ?? DateTime.now();

  bool get isVideo => mediaType == MediaType.video;
  bool get isPhoto => mediaType == MediaType.photo;

  String get fileExtension {
    // On web, filePath is a blob URL, so we need to get extension from XFile.name
    if (xFile != null) {
      final name = (xFile as dynamic).name as String?;
      if (name != null) {
        final parts = name.split('.');
        return parts.length > 1 ? parts.last.toLowerCase() : 'jpg';
      }
    }
    
    // Fallback: try to get from filePath
    final parts = filePath.split('.');
    if (parts.length > 1 && !filePath.startsWith('blob:')) {
      return parts.last.toLowerCase();
    }
    
    // Default extension based on media type
    return isVideo ? 'mp4' : 'jpg';
  }

  String get fileName {
    // On web, get filename from XFile
    if (xFile != null) {
      final name = (xFile as dynamic).name as String?;
      if (name != null) return name;
    }
    
    final parts = filePath.split('/');
    return parts.isNotEmpty ? parts.last : filePath;
  }

  String get storagePath {
    final ext = fileExtension;
    final timestampStr = timestamp.millisecondsSinceEpoch.toString();
    final typeFolder = isVideo ? 'videos' : 'photos';
    return 'datasets/$datasetName/$classLabel/$typeFolder/${classLabel}_$timestampStr.$ext';
  }

  MediaData copyWith({
    String? id,
    String? filePath,
    String? classLabel,
    String? datasetName,
    DateTime? timestamp,
    MediaType? mediaType,
    UploadStatus? status,
    double? uploadProgress,
    String? errorMessage,
    dynamic xFile,
  }) {
    return MediaData(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      classLabel: classLabel ?? this.classLabel,
      datasetName: datasetName ?? this.datasetName,
      timestamp: timestamp ?? this.timestamp,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      xFile: xFile ?? this.xFile,
    );
  }

  @override
  String toString() {
    return 'MediaData(id: $id, classLabel: $classLabel, datasetName: $datasetName, '
        'mediaType: $mediaType, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
