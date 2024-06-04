import 'package:flutter/material.dart';
import 'photo_screen.dart';
import 'video_screen.dart';

class LandingScreen extends StatelessWidget {
  static const routeName = '/landing';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Landing Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(PhotoScreen.routeName);
              },
              child: Text('Go to Photo Upload Screen'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(VideoScreen.routeName);
              },
              child: Text('Go to Video Upload Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
