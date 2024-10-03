import 'package:flutter/material.dart';
import 'login.dart';
import 'explore.dart';
import 'chatbot.dart'; // Import ChatbotPage

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool isUsernameEditable = false;
  bool isEmailEditable = false;
  bool isPhoneEditable = false;
  bool isPasswordEditable = false;

  final TextEditingController _usernameController =
      TextEditingController(text: 'JohnDoe');
  final TextEditingController _emailController =
      TextEditingController(text: 'john@example.com');
  final TextEditingController _phoneController =
      TextEditingController(text: '1234567890');
  final TextEditingController _passwordController =
      TextEditingController(text: 'password');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEDEDED), // Light grayish
              Color(0xFFF6F6F6), // Soft light color
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),

            // Profile heading at the top center
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Circular avatar placeholder
            const CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(
                  'assets/avatar_placeholder.png'), // Add your avatar image or a placeholder
              backgroundColor: Colors.grey,
            ),

            const SizedBox(height: 40),

            // Username
            buildEditableField(
              label: 'Username',
              isEditable: isUsernameEditable,
              controller: _usernameController,
              onEditToggle: () {
                setState(() {
                  isUsernameEditable = !isUsernameEditable;
                });
              },
            ),

            const SizedBox(height: 20),

            // Email
            buildEditableField(
              label: 'Email',
              isEditable: isEmailEditable,
              controller: _emailController,
              onEditToggle: () {
                setState(() {
                  isEmailEditable = !isEmailEditable;
                });
              },
            ),

            const SizedBox(height: 20),

            // Phone Number
            buildEditableField(
              label: 'Phone Number',
              isEditable: isPhoneEditable,
              controller: _phoneController,
              onEditToggle: () {
                setState(() {
                  isPhoneEditable = !isPhoneEditable;
                });
              },
            ),

            const SizedBox(height: 20),

            // Password
            buildEditableField(
              label: 'Password',
              isEditable: isPasswordEditable,
              controller: _passwordController,
              obscureText: true,
              onEditToggle: () {
                setState(() {
                  isPasswordEditable = !isPasswordEditable;
                });
              },
            ),

            const Spacer(),

            // Sign out button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to LoginPage on sign-out
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEF5350), // Red-ish button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Reusing the same bottom navigation bar as in ExplorePage
            Container(
              margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExplorePage(),
                            ),
                          );
                        },
                        child: _buildNavItemWithImage(
                          imagePath: 'assets/logo1.png',
                          label: 'Home',
                          isSelected: false, // Not selected in AccountPage
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatbotPage(),
                            ),
                          );
                        },
                        child: _buildNavItemWithImage(
                          imagePath: 'assets/chatbot.png',
                          label: 'WanderBot',
                          isSelected: false,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(Icons.luggage, 'Trips'),
                    ),
                    Expanded(
                      child: _buildNavItem(Icons.vrpano_rounded, 'VR Tour'),
                    ),
                    Expanded(
                      child: _buildNavItem(Icons.person_outline, 'Account',
                          isSelected: true), // Account is selected
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the editable field with the option to toggle between text and TextField.
  Widget buildEditableField({
    required String label,
    required bool isEditable,
    required TextEditingController controller,
    bool obscureText = false,
    required VoidCallback onEditToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  isEditable ? Icons.check : Icons.edit,
                  color: Colors.black,
                ),
                onPressed: onEditToggle,
              ),
            ],
          ),
          isEditable
              ? TextField(
                  controller: controller,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )
              : Text(
                  controller.text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
        ],
      ),
    );
  }

  /// Builds a navigation item with an image asset.
  Widget _buildNavItemWithImage({
    required String imagePath,
    required String label,
    bool isSelected = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          imagePath,
          width: 24,
          height: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.grey : Colors.black,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Builds a standard navigation item with an icon.
  Widget _buildNavItem(IconData icon, String label, {bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.black,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.black,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
