import 'package:flutter/material.dart';
import 'opening.dart'; // Make sure this is the correct path to OpeningPage
import 'login.dart'; // Import your LoginPage
import 'register.dart'; // Import your RegisterPage

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Apply a light blue gradient background to the entire page
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB3E5FC), // Light blue at the top
              Color(0xFFE1F5FE), // Lighter blue in the middle
              Color(0xFFE3F2FD), // Very light blue at the bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom back button without AppBar
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    // Navigate back to the OpeningPage
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OpeningPage(),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background gradient behind the image
                      Container(
                        width: 600,
                        height: 600,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFB3E5FC)
                                  .withOpacity(0.5), // Light blue at the top
                              Color(0xFFE1F5FE).withOpacity(
                                  0.5), // Lighter blue in the middle
                              Color(0xFFE3F2FD).withOpacity(
                                  0.5), // Very light blue at the bottom
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Logo with opacity to blend better
                      Opacity(
                        opacity: 0.9,
                        child: Image.asset(
                          'assets/home.png', // Make sure the logo path is correct
                          width: 600,
                          height: 600, // Resizing the image
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20), // Space between image and text
              // New travel-related texts
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: const [
                    Text(
                      'Explore New Destinations!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Discover hidden gems and start your next adventure with us.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87, // Darker text color
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30), // Space between text and buttons
                  ],
                ),
              ),
              // Buttons section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Login Button
                    SizedBox(
                      width: double.infinity, // Full-width button
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to LoginPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF42A5F5), // Darker button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Space between buttons
                    // Register Button
                    SizedBox(
                      width: double.infinity, // Full-width button
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to RegisterPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                              0xFF42A5F5), // Same darker background color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40), // Bottom padding for spacing
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
