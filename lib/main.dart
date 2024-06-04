import 'package:flutter/material.dart';
import 'package:media_upload/services/video_selector.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/photo_screen.dart';
import 'screens/video_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/camera_screen.dart';
import 'providers/media_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCrgp0v12XTtTYgGR0kTF4yFQWOD_Q8YaY',
      appId: '1:502454218028:android:83cf68672b218a11021089',
      messagingSenderId: '502454218028',
      projectId: 'media-upload-project',
      storageBucket: 'media-upload-project.appspot.com',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MediaProvider(),
      child: MaterialApp(
        title: 'Flutter Firebase Storage',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: LandingScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == CameraScreen.routeName) {
            final args = settings.arguments as String?;
            if (args != null) {
              return MaterialPageRoute(
                builder: (context) {
                  return CameraScreen(filePath: args);
                },
              );
            }
          }
          return null; // Return null to use the default unknown route handling
        },
        routes: {
          PhotoScreen.routeName: (ctx) => PhotoScreen(),
          VideoScreen.routeName: (ctx) => VideoScreen(),
          VideoSelector.routeName: (ctx) => VideoSelector(),
        },
      ),
    );
  }
}
