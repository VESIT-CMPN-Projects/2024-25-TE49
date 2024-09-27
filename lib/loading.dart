import 'package:flutter/material.dart';
import 'opening.dart'; // Make sure this import points to the correct OpeningPage file

class LoadingPage extends StatefulWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();

    // Navigate to OpeningPage after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const OpeningPage()), // Ensure OpeningPage is correctly referenced here
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sky blue background
      body: Center(
        child: Image.asset('assets/logo.png', // Path to the image
            width: 450, // Adjust size as needed
            height: 450),
      ),
    );
  }
}
