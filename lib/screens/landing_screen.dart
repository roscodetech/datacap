import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:media_upload/services/video_selector.dart';
// import 'camera_screen.dart';
import 'photo_screen.dart';
import 'video_screen.dart';

class LandingScreen extends StatelessWidget {
  // final ImagePicker _picker = ImagePicker();

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
              onPressed: () {
                Navigator.of(context).pushNamed(VideoSelector.routeName);
              },
              child: const Text('Go to Video Select Screen'),
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
