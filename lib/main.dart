import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import '../providers/media_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
    apiKey: 'AIzaSyCrgp0v12XTtTYgGR0kTF4yFQWOD_Q8YaY',
    appId: '1:502454218028:android:83cf68672b218a11021089',
    messagingSenderId: '502454218028',
    projectId: 'media-upload-project',
    storageBucket: 'media-upload-project.appspot.com',
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MediaProvider(),
      child: MaterialApp(
        title: 'Flutter Firebase Storage',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: HomeScreen(),
      ),
    );
  }
}
