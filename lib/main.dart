import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/sign_in_screen.dart';
import 'providers/media_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On web, we need to provide FirebaseOptions manually
  // On Android/iOS, Firebase is auto-initialized via google-services.json/GoogleService-Info.plist
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDS2hQa8oUZlXlrTAZB58EykuARblwfDJ4',
        authDomain: 'media-upload-project.firebaseapp.com',
        projectId: 'media-upload-project',
        storageBucket: 'media-upload-project.appspot.com',
        messagingSenderId: '502454218028',
        appId: '1:502454218028:web:c7f98b547831a34c021089',
        measurementId: 'G-N25LGQB9N2',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const DataCapApp());
}

class DataCapApp extends StatelessWidget {
  const DataCapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MediaProvider(),
      child: MaterialApp(
        title: 'DataCap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          CaptureScreen.routeName: (ctx) => const CaptureScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const SignInScreen();
      },
    );
  }
}
