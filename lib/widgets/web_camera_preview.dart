import 'package:flutter/material.dart';

import 'web_camera_preview_stub.dart'
    if (dart.library.html) 'web_camera_preview_web.dart' as impl;

class WebCameraPreview extends StatelessWidget {
  final String viewId;

  const WebCameraPreview({super.key, required this.viewId});

  @override
  Widget build(BuildContext context) {
    return impl.buildCameraPreview(viewId);
  }
}
