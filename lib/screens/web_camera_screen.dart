import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/web_camera_service.dart';
import '../services/web_camera_stub.dart' if (dart.library.html) '../services/web_camera_web.dart' as web_impl;
import '../widgets/web_camera_preview.dart';

class WebCameraScreen extends StatefulWidget {
  final bool isVideo;

  const WebCameraScreen({
    super.key,
    this.isVideo = false,
  });

  @override
  State<WebCameraScreen> createState() => _WebCameraScreenState();
}

class _WebCameraScreenState extends State<WebCameraScreen> {
  WebCameraController? _controller;
  web_impl.WebCameraControllerImpl? _webController;
  bool _isInitializing = true;
  String? _error;
  bool _isCapturing = false;
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = await WebCameraService.initialize(enableAudio: widget.isVideo);
      if (_controller == null) {
        setState(() {
          _error = 'Camera not available on this platform';
          _isInitializing = false;
        });
        return;
      }
      try {
        _webController = _controller as web_impl.WebCameraControllerImpl?;
      } catch (_) {
        _webController = null;
      }
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to access camera: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final bytes = await _controller!.capturePhoto();
      if (bytes != null && mounted) {
        final xFile = XFile.fromData(
          bytes,
          name: 'photo_${DateTime.now().millisecondsSinceEpoch}.png',
          mimeType: 'image/png',
        );
        Navigator.of(context).pop(xFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _startRecording() {
    if (_webController == null || _isRecording) return;

    _webController!.startRecording();
    _recordingDuration = Duration.zero;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    if (_webController == null || !_isRecording) return;

    _recordingTimer?.cancel();
    _recordingTimer = null;

    setState(() => _isCapturing = true);

    try {
      final bytes = await _webController!.stopRecording();
      if (bytes != null && mounted) {
        final xFile = XFile.fromData(
          bytes,
          name: 'video_${DateTime.now().millisecondsSinceEpoch}.webm',
          mimeType: 'video/webm',
        );
        Navigator.of(context).pop(xFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save video: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isCapturing = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.isVideo ? 'Record Video' : 'Take Photo'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: AppSpacing.md),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isVideo ? Icons.videocam_outlined : Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final viewId = _webController?.viewId;

    if (viewId == null) {
      return const Center(
        child: Text(
          'Camera not available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        WebCameraPreview(viewId: viewId),

        // Recording indicator
        if (_isRecording)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Capture/Record button
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: widget.isVideo ? _buildVideoButton() : _buildPhotoButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _capturePhoto,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isCapturing ? Colors.grey : Colors.white,
          ),
          child: _isCapturing
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildVideoButton() {
    return GestureDetector(
      onTap: _isCapturing
          ? null
          : (_isRecording ? _stopRecording : _startRecording),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: _isRecording ? BorderRadius.circular(8) : null,
            color: _isCapturing ? Colors.grey : Colors.red,
          ),
          child: _isCapturing
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : (_isRecording
                  ? const Center(
                      child: Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                  : null),
        ),
      ),
    );
  }
}
