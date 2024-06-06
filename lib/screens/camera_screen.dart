import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  static const routeName = '/camera-screen';

  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  late String _filePath;
  late List<CameraDescription> _cameras;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    bool permissionsGranted = await _checkAndRequestPermissions();
    if (permissionsGranted) {
      _initializeCamera();
    } else {
      _showErrorDialog(
          'Permissions not granted. The app cannot function without the necessary permissions.');
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    bool cameraPermission = await Permission.camera.request().isGranted;
    bool microphonePermission = await Permission.microphone.request().isGranted;
    // bool storagePermission = await Permission.storage.request().isGranted;
    bool manageStoragePermission = await _checkManageStoragePermission();

    if (cameraPermission &&
        microphonePermission &&
        // storagePermission &&
        manageStoragePermission) {
      return true;
    } else {
      _showDetailedErrorDialog({
        Permission.camera: cameraPermission,
        Permission.microphone: microphonePermission,
        // Permission.storage: storagePermission,
        Permission.manageExternalStorage: manageStoragePermission
      });
      return false;
    }
  }

  Future<bool> _checkManageStoragePermission() async {
    if (Platform.isAndroid && (await Permission.storage.isRestricted)) {
      return await Permission.manageExternalStorage.request().isGranted;
    }
    return true;
  }

  void _showDetailedErrorDialog(Map<Permission, bool> statuses) {
    String message = "The following permissions were not granted:\n";
    statuses.forEach((permission, granted) {
      if (!granted) {
        message += "- ${permission.toString().split('.').last}\n";
      }
    });

    _showErrorDialog(message);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _cameraController = CameraController(_cameras[0], ResolutionPreset.high);
      await _cameraController!.initialize();
      setState(() {
        _permissionsGranted = true;
      });
    } catch (e) {
      _showErrorDialog('Error initializing camera: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorDialog('Error: Camera is not initialized.');
      return;
    }

    final Directory directory = await getApplicationDocumentsDirectory();
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    _filePath = '${directory.path}/VID_$timestamp.mp4';
    print('Saving video to: $_filePath');

    try {
      await _cameraController!.startVideoRecording();
      print('Video recording started.');
    } catch (e) {
      _showErrorDialog('Error starting video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isRecordingVideo) {
      return;
    }

    try {
      await _cameraController!.stopVideoRecording();
      print('Video recording stopped.');
      _initVideoPlayer();
    } catch (e) {
      _showErrorDialog('Error stopping video recording: $e');
    }
  }

  Future<void> _initVideoPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.file(File(_filePath));
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.play();
      setState(() {});
      print('Video playback initialized.');
    } catch (e) {
      _showErrorDialog('Error initializing video playback: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        elevation: 0,
        backgroundColor: Colors.black26,
      ),
      extendBodyBehindAppBar: true,
      body: _permissionsGranted &&
              _cameraController != null &&
              _cameraController!.value.isInitialized
          ? Column(
              children: [
                AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
                if (_videoPlayerController != null &&
                    _videoPlayerController!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController!),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.videocam),
                      onPressed: _startVideoRecording,
                    ),
                    IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: _stopVideoRecording,
                    ),
                  ],
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
