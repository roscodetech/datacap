import 'dart:typed_data';
import 'web_camera_service.dart';

Future<WebCameraController?> initializeCamera({bool enableAudio = false}) async {
  return null;
}

class WebCameraControllerImpl implements WebCameraController {
  @override
  dynamic get videoElement => null;

  @override
  Stream<Uint8List>? get onFrame => null;

  String? get viewId => null;

  bool get isRecording => false;

  @override
  Future<Uint8List?> capturePhoto() async => null;

  void startRecording() {}

  Future<Uint8List?> stopRecording() async => null;

  @override
  void dispose() {}
}
