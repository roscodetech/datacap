import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import 'photo_screen.dart';
import 'video_screen.dart';

class LandingScreen extends StatelessWidget {
  final ImagePicker _picker = ImagePicker();

  LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landing Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final XFile? video =
                    await _picker.pickVideo(source: ImageSource.camera);
                if (video != null) {
                  Navigator.of(context).pushNamed(
                    CameraScreen.routeName,
                    arguments: video.path,
                  );
                }
              },
              child: const Text('Capture Video'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(PhotoScreen.routeName);
              },
              child: const Text('Go to Photo Screen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(VideoScreen.routeName);
              },
              child: const Text('Go to Video Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
