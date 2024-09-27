import 'package:flutter/material.dart';
import 'loading.dart'; // Import the LoadingPage

void main() {
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
