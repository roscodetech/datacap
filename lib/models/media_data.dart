class MediaData {
  final String filePath;
  final String animalName;
  final String farmName;
  final DateTime timestamp;
  final bool isVideo; // Add this field to determine if the file is a video

  MediaData({
    required this.filePath,
    required this.animalName,
    required this.farmName,
    required this.timestamp,
    this.isVideo = false, // Default to false for backward compatibility
  });
}
