import 'package:flutter/material.dart';
import 'loading.dart'; // Import the LoadingPage
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import firebase options

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Initialize Firebase with platform-specific options
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journey Genie',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green), // Seed color for theming
        useMaterial3: true,
      ),
      home: const LoadingPage(), // Set the LoadingPage as the initial screen
    );
  }
}
