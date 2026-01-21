import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'web_camera_service.dart';

Future<WebCameraController?> initializeCamera({bool enableAudio = false}) async {
  try {
    final controller = WebCameraControllerImpl();
    await controller._initialize(enableAudio: enableAudio);
    return controller;
  } catch (e) {
    print('Failed to initialize web camera: $e');
    return null;
  }
}

class WebCameraControllerImpl implements WebCameraController {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob>? _recordedChunks;
  String? _viewId;
  bool _isRecording = false;
  Completer<Uint8List?>? _recordingCompleter;

  @override
  dynamic get videoElement => _videoElement;

  @override
  Stream<Uint8List>? get onFrame => null;

  bool get isRecording => _isRecording;

  Future<void> _initialize({bool enableAudio = false}) async {
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.objectFit = 'cover'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.transform = 'scaleX(-1)'; // Mirror for selfie camera

    _mediaStream = await html.window.navigator.mediaDevices?.getUserMedia({
      'video': {
        'facingMode': 'environment', // Use back camera if available
        'width': {'ideal': 1920},
        'height': {'ideal': 1080},
      },
      'audio': enableAudio,
    });

    if (_mediaStream != null) {
      _videoElement!.srcObject = _mediaStream;
      await _videoElement!.play();

      // Register the video element for HtmlElementView
      _viewId = 'webcam-${DateTime.now().millisecondsSinceEpoch}';
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId!,
        (int viewId) => _videoElement!,
      );
    }
  }

  String? get viewId => _viewId;

  @override
  Future<Uint8List?> capturePhoto() async {
    if (_videoElement == null) return null;

    final canvas = html.CanvasElement(
      width: _videoElement!.videoWidth,
      height: _videoElement!.videoHeight,
    );

    final ctx = canvas.context2D;

    // Draw mirrored image
    ctx.translate(canvas.width!, 0);
    ctx.scale(-1, 1);
    ctx.drawImage(_videoElement!, 0, 0);

    final dataUrl = canvas.toDataUrl('image/png');
    final base64 = dataUrl.split(',')[1];

    // Convert base64 to bytes
    final bytes = _base64ToBytes(base64);
    return bytes;
  }

  void startRecording() {
    if (_mediaStream == null || _isRecording) return;

    _recordedChunks = [];
    _recordingCompleter = Completer<Uint8List?>();

    // Try to use webm with vp9, fallback to webm with vp8
    String mimeType = 'video/webm;codecs=vp9';
    if (!html.MediaRecorder.isTypeSupported(mimeType)) {
      mimeType = 'video/webm;codecs=vp8';
    }
    if (!html.MediaRecorder.isTypeSupported(mimeType)) {
      mimeType = 'video/webm';
    }

    _mediaRecorder = html.MediaRecorder(_mediaStream!, {'mimeType': mimeType});

    _mediaRecorder!.addEventListener('dataavailable', (event) {
      final blobEvent = event as html.BlobEvent;
      if (blobEvent.data != null && blobEvent.data!.size > 0) {
        _recordedChunks!.add(blobEvent.data!);
      }
    });

    _mediaRecorder!.addEventListener('stop', (event) async {
      if (_recordedChunks != null && _recordedChunks!.isNotEmpty) {
        final blob = html.Blob(_recordedChunks!, 'video/webm');
        final bytes = await _blobToBytes(blob);
        _recordingCompleter?.complete(bytes);
      } else {
        _recordingCompleter?.complete(null);
      }
    });

    _mediaRecorder!.start();
    _isRecording = true;
  }

  Future<Uint8List?> stopRecording() async {
    if (!_isRecording || _mediaRecorder == null) return null;

    _mediaRecorder!.stop();
    _isRecording = false;

    return _recordingCompleter?.future;
  }

  Future<Uint8List> _blobToBytes(html.Blob blob) async {
    final reader = html.FileReader();
    final completer = Completer<Uint8List>();

    reader.onLoadEnd.listen((event) {
      final result = reader.result as List<int>;
      completer.complete(Uint8List.fromList(result));
    });

    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  Uint8List _base64ToBytes(String base64) {
    final decoded = html.window.atob(base64);
    final bytes = Uint8List(decoded.length);
    for (var i = 0; i < decoded.length; i++) {
      bytes[i] = decoded.codeUnitAt(i);
    }
    return bytes;
  }

  @override
  void dispose() {
    if (_isRecording) {
      _mediaRecorder?.stop();
    }
    _mediaRecorder = null;
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _videoElement?.pause();
    _videoElement?.srcObject = null;
    _videoElement = null;
    _mediaStream = null;
  }
}
