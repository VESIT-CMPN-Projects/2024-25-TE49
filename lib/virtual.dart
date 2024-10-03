import 'package:flutter/material.dart';
import 'chatbot.dart';
import 'account.dart';
import 'explore.dart';

class VirtualPage extends StatefulWidget {
  @override
  _VirtualPageState createState() => _VirtualPageState();
}

class _VirtualPageState extends State<VirtualPage> {
  bool _showSearch = false;
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1D1B27),
              Color(0xFF4B0082),
              Color(0xFF7D3C98),
              Color(0xFF4B0082),
              Color(0xFF1D1B27),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top bar with search, title, and plus icon
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _showSearch
                          ? Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    icon:
                                        Icon(Icons.clear, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        _showSearch = false;
                                        _searchController.clear();
                                      });
                                    },
                                  ),
                                ),
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : IconButton(
                              icon: Icon(Icons.search, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _showSearch = true;
                                });
                              },
                            ),
                      if (!_showSearch) Icon(Icons.add, color: Colors.white),
                    ],
                  ),
                ),

                // Image and text side by side
                Container(
                  margin:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // VR Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 190,
                          child: Image.asset(
                            'assets/vr.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      // Text beside the image
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Explore Beyond the Ordinary",
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[350],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10), // Reduced gap

                // More options instead of plus sign in the middle (e.g., Kalaw, Baoji)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.0),
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  height: 170,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      buildLocationCard('Kalaw', 'assets/kalaw.png'),
                      buildLocationCard('Baoji', 'assets/baoji.png'),
                      buildLocationCard('Egypt', 'assets/egypt.png'),
                      buildLocationCard('Manali', 'assets/manali.png'),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Start a video tour section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.0),
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Start a video tour",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.filter_list, color: Colors.yellow),
                            label: Text(
                              "Filter",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      buildVideoTourCard(),
                    ],
                  ),
                ),

                // Leave space for the bottom navbar
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home,
                label: 'Home',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ExplorePage()));
                },
              ),
              _buildNavItem(
                context: context,
                icon: Icons.chat,
                label: 'WanderBot',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ChatbotPage()));
                },
              ),
              _buildNavItem(
                context: context,
                icon: Icons.luggage,
                label: 'Trips',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ExplorePage()));
                },
              ),
              _buildNavItem(
                context: context,
                icon: Icons.vrpano_rounded,
                label: 'VR Tour',
                isSelected: true,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                label: 'Account',
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AccountPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a navigation item with an icon.
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.black,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.black,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for building location cards
  Widget buildLocationCard(String title, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          // Location Image
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 10),
          // Location title text
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for building the video tour card
  Widget buildVideoTourCard() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage('assets/video_tour.png'),
          fit: BoxFit.cover,
        ),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Khon Kaen, Thailand",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.yellow),
                  Text(
                    "2,443",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
          Text(
            "The active volcano of the island of Khon Kaen",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text("Join"),
          ),
        ],
      ),
    );
  }
}
