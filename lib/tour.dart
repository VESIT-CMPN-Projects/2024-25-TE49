import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'dart:convert';
import 'explore.dart'; // Import explore page for back navigation

class TourPage extends StatefulWidget {
  @override
  _TourPageState createState() => _TourPageState();
}

class _TourPageState extends State<TourPage> {
  Position? _currentLocation;
  List<PointOfInterest> _pointsOfInterest = [];
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeTour();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    _currentLocation = await Geolocator.getCurrentPosition();
    setState(() {});
  }

  Future<void> _fetchNearbyHistoricalSites() async {
    if (_currentLocation == null) return;

    setState(() {
      _pointsOfInterest = [
        PointOfInterest(
          name: 'Ancient Temple',
          latitude: _currentLocation!.latitude + 0.01,
          longitude: _currentLocation!.longitude + 0.01,
          description: 'A historic temple with rich cultural significance',
          imageUrl: 'https://example.com/temple.jpg',
        ),
        PointOfInterest(
          name: 'Historical Museum',
          latitude: _currentLocation!.latitude - 0.01,
          longitude: _currentLocation!.longitude - 0.01,
          description: 'Museum showcasing local history and artifacts',
          imageUrl: 'https://example.com/museum.jpg',
        ),
      ];

      _markers = _pointsOfInterest
          .map(
            (poi) => Marker(
              markerId: MarkerId(poi.name),
              position: LatLng(poi.latitude, poi.longitude),
              infoWindow: InfoWindow(
                title: poi.name,
                snippet: poi.description,
              ),
            ),
          )
          .toSet();
    });
  }

  Future<String> _generateHistoricalFact(PointOfInterest poi) async {
    final String? apiKey = dotenv.env['OPENAI_API_KEY']; // Secure API Key

    if (apiKey == null || apiKey.isEmpty) {
      return 'API Key is missing!';
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey', // Use environment variable
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'user',
              'content': 'Generate a historical fact about ${poi.name}.'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'] ??
            'No historical fact available.';
      } else {
        return 'Failed to generate historical fact.';
      }
    } catch (e) {
      return 'Error generating historical fact.';
    }
  }

  Future<void> _initializeTour() async {
    await _getUserLocation();
    await _fetchNearbyHistoricalSites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ExplorePage()),
            );
          },
        ),
        title: Text('Historical Walking Tour'),
      ),
      body: Stack(
        children: [
          _currentLocation != null
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentLocation!.latitude,
                      _currentLocation!.longitude,
                    ),
                    zoom: 14,
                  ),
                  markers: _markers,
                  onMapCreated: (controller) {
                    setState(() {
                      _mapController = controller;
                    });
                  },
                )
              : Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                  )
                ],
              ),
              child: _pointsOfInterest.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pointsOfInterest.length,
                      itemBuilder: (context, index) {
                        final poi = _pointsOfInterest[index];
                        return _buildPoiCard(poi);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoiCard(PointOfInterest poi) {
    return Container(
      width: 250,
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              poi.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: Center(
                    child: Text(
                      'Image Not Available',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poi.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                FutureBuilder<String>(
                  future: _generateHistoricalFact(poi),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Loading historical insight...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      );
                    } else {
                      return Text(
                        snapshot.data ?? 'No historical fact available.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PointOfInterest {
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final String imageUrl;

  PointOfInterest({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.imageUrl,
  });
}
