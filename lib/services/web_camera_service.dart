import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for web
import 'web_camera_stub.dart' if (dart.library.html) 'web_camera_web.dart'
    as camera_impl;

class WebCameraService {
  static Future<WebCameraController?> initialize({bool enableAudio = false}) async {
    if (!kIsWeb) return null;
    return camera_impl.initializeCamera(enableAudio: enableAudio);
  }
}

abstract class WebCameraController {
  dynamic get videoElement;
  Stream<Uint8List>? get onFrame;
  Future<Uint8List?> capturePhoto();
  void dispose();
}
