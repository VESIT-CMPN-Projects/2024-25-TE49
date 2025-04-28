import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walking Tour',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF5D5FEF),
          brightness: Brightness.light,
        ),
        fontFamily: GoogleFonts.poppins().fontFamily,
        textTheme: TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF5D5FEF),
          brightness: Brightness.dark,
        ),
        fontFamily: GoogleFonts.poppins().fontFamily,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: TourPage(),
    );
  }
}

class TourPage extends StatefulWidget {
  @override
  _TourPageState createState() => _TourPageState();
}

class _TourPageState extends State<TourPage> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _exploring = false;
  Position? _position;
  final List<PointOfInterest> _poiList = [];
  List<Marker> _markers = [];
  String _geoApiKey = '';
  String _geminiApiKey = '';
  MapController _mapController = MapController();
  late TabController _tabController;
  int _selectedPoiIndex = -1;
  bool _showTooltip = false;
  double _mapZoom = 14.0;

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _loadApiKeys() async {
    try {
      _geoApiKey = dotenv.env[''] ?? '';
      _geminiApiKey = dotenv.env[''] ?? '';

      // Print keys for debugging (remove in production)
      print("Geo API Key loaded: ${_geoApiKey.isNotEmpty ? 'Yes' : 'No'}");
      print(
          "Gemini API Key loaded: ${_geminiApiKey.isNotEmpty ? 'Yes' : 'No'}");

      if (_geoApiKey.isEmpty || _geminiApiKey.isEmpty) {
        Future.delayed(Duration.zero, () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('API keys not found. Please check your .env file.'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    } catch (e) {
      print("Error loading API keys: $e");
    }
  }

  Future<void> _startExploring() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar(
            'Location services are disabled. Please enable them in your device settings.');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar(
              'Location permissions are denied. The app needs location access to work.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar(
            'Location permissions are permanently denied. Please enable them in app settings.');
        return;
      }

      // Get current position
      _position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Find POIs
      await _findNearbyPointsOfInterest();
      _buildMarkers();

      setState(() {
        _exploring = true;
      });
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _findNearbyPointsOfInterest() async {
    _poiList.clear();

    // Absolute coordinates for Chembur area landmarks
    List<Map<String, dynamic>> chemburPois = [
      {
        'name': 'Vivekanand Education Society\'s Institute Of Technology',
        'lat': 19.0428,
        'lng': 72.9001,
        'type': 'education',
        'year': 1984,
      },
      {
        'name': 'Bombay Presidency Golf Club',
        'lat': 19.0550,
        'lng': 72.9090,
        'type': 'recreation',
        'year': 1927,
      },
      {
        'name': 'RK Studios',
        'lat': 19.0547,
        'lng': 72.8993,
        'type': 'landmark',
        'year': 1948,
      },
      {
        'name': 'Diamond Garden',
        'lat': 19.0561,
        'lng': 72.8918,
        'type': 'recreation',
        'year': 1947,
      },
      {
        'name': 'Fine Arts Cultural Centre',
        'lat': 19.0495,
        'lng': 72.8975,
        'type': 'cultural',
        'year': 1968,
      },
    ];

    for (var poi in chemburPois) {
      // Get historical information from Gemini API
      String description =
          await _getHistoricalInfo(poi['name'], poi['type'], poi['year']);

      _poiList.add(
        PointOfInterest(
          poi['name'],
          LatLng(poi['lat'], poi['lng']),
          description,
          poi['type'],
          poi['year'],
        ),
      );
    }
  }

  Future<String> _getHistoricalInfo(String name, String type, int year) async {
    // Prepare fallback descriptions for each location
    Map<String, String> fallbackDescriptions = {
      'Vivekanand Education Society\'s Institute Of Technology':
          "Established in 1984, VES Institute of Technology is a prestigious engineering college in Chembur, Mumbai. Known for its excellence in technical education, the college offers undergraduate and postgraduate programs in various engineering disciplines. The campus features modern facilities, laboratories, and is affiliated with the University of Mumbai.",
      'Bombay Presidency Golf Club':
          "Established in 1927, the Bombay Presidency Golf Club is one of Mumbai's most prestigious sporting institutions. Located in Chembur, this 18-hole course has hosted numerous national and international tournaments. The club features classic colonial architecture and lush greens that provide a serene escape from Mumbai's urban landscape.",
      'NuAyurveda':
          "Founded in 2010, NuAyurveda represents a modern take on traditional Indian wellness practices. This center combines ancient Ayurvedic principles with contemporary wellness approaches. Located in a peaceful setting, it offers treatments ranging from therapeutic massages to personalized health consultations, becoming a sanctuary for those seeking holistic health solutions.",
      'Jio World Centre':
          "The Jio World Centre, established in 2019, is a landmark business and cultural hub in the Bandra Kurla Complex. Developed by Reliance Industries, this massive complex spans approximately 18.5 acres and houses exhibition spaces, a performing arts theater, retail outlets, offices, and convention facilities. Its fountain show is considered one of the largest in the world.",
      'Jio World Drive':
          "Opened in 2021, Jio World Drive is Mumbai's premium retail destination in the Bandra Kurla Complex. This luxury mall features international and Indian brands, gourmet dining options, and entertainment facilities including an IMAX theater. The architecture incorporates sustainable design elements and digital art installations, creating a modern shopping experience.",
      'Band Stand Bandra':
          "Dating back to 1864, Band Stand is a historic promenade along the Arabian Sea in Bandra. Originally built during British colonial rule, it served as a place where bands would perform for the public. Today, it's famous for stunning sunset views, the Bandra Fort, and homes of several Bollywood celebrities. The 1.2 km walkway has become an iconic Mumbai landmark.",
    };

    try {
      // First try to use the API if keys are available
      if (_geminiApiKey.isNotEmpty) {
        final response = await http.post(
          Uri.parse(
              'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        'Create a brief historical overview (100 words) for "$name" in Mumbai established in $year. Include important historical facts and why visitors should be interested in this place.'
                  }
                ]
              }
            ],
            'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 250}
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          try {
            final result = data['candidates'][0]['content']['parts'][0]['text'];
            if (result != null && result.toString().trim().isNotEmpty) {
              return result;
            }
          } catch (e) {
            print("Error parsing Gemini response: $e");
            // Fall through to use fallback
          }
        } else {
          print("Gemini API error: ${response.statusCode} - ${response.body}");
          // Fall through to use fallback
        }
      }

      // Return fallback description if API call failed or wasn't attempted
      return fallbackDescriptions[name] ??
          "This site dates back to $year and represents an important part of Mumbai's heritage.";
    } catch (e) {
      print("Exception getting historical info: $e");
      // Use fallback in case of any exception
      return fallbackDescriptions[name] ??
          "This site dates back to $year. It's an important landmark in Mumbai worth exploring.";
    }

    // Ensure a return statement exists for all code paths
    return "No information available for $name.";
  }

  void _buildMarkers() {
    _markers = [];

    // User location marker
    _markers.add(
      Marker(
        width: 60,
        height: 60,
        point: LatLng(_position!.latitude, _position!.longitude),
        builder: (_) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.3),
          ),
          child: Center(
            child: Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ),
      ),
    );

    // POI markers
    for (var i = 0; i < _poiList.length; i++) {
      var poi = _poiList[i];
      _markers.add(
        Marker(
          width: 150, // Increased width to handle tooltip text
          height: _selectedPoiIndex == i && _showTooltip
              ? 80
              : 40, // Dynamic height
          point: poi.location,
          builder: (_) => GestureDetector(
            onTap: () => _selectPoi(i),
            child: Stack(
              // Changed to Stack instead of Column to avoid overflow
              children: [
                // The marker icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedPoiIndex == i
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconForType(poi.type),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                // The tooltip
                if (_selectedPoiIndex == i && _showTooltip)
                  Positioned(
                    top: 45, // Position below the marker
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      constraints:
                          BoxConstraints(maxWidth: 140), // Constrain width
                      child: Text(
                        poi.name,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis, // Handle overflow text
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'recreation':
        return Icons.golf_course;
      case 'wellness':
        return Icons.spa;
      case 'business':
        return Icons.business_center;
      case 'shopping':
        return Icons.shopping_bag;
      case 'landmark':
        return Icons.landscape;
      default:
        return Icons.place;
    }
  }

  void _selectPoi(int index) {
    setState(() {
      _selectedPoiIndex = index;
      _showTooltip = true;
    });

    // Center the map on this POI
    _mapController.move(_poiList[index].location, _mapZoom);

    // Show detail panel
    _showPoiDetails(_poiList[index]);

    // Hide tooltip after delay
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTooltip = false;
        });
      }
    });
  }

  void _showPoiDetails(PointOfInterest poi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: PoiDetailCard(poi: poi),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _exploring ? _buildExploringView() : _buildStartScreen(),
    );
  }

  Widget _buildStartScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5D5FEF), Color(0xFF3F51B5)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo/Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.explore,
                            size: 80,
                            color: Color(0xFF5D5FEF),
                          ),
                        ),
                        SizedBox(height: 40),
                        Text(
                          'Mumbai Walking Tour',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Discover the hidden history around World with AI-powered insights',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 60),
                        _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : ElevatedButton(
                                onPressed: _startExploring,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Color(0xFF5D5FEF),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.near_me),
                                    SizedBox(width: 8),
                                    Text(
                                      'Start Exploring',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Powered by Gemini AI',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploringView() {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(_position!.latitude, _position!.longitude),
              zoom: _mapZoom,
              maxZoom: 18,
              interactiveFlags: InteractiveFlag.all,
            ),
            children: [
              TileLayer(
                // Use OpenStreetMap tiles as fallback if Geoapify key is not configured
                urlTemplate: _geoApiKey.isNotEmpty
                    ? 'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=$_geoApiKey'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mumbaiwalkingtour',
                subdomains: ['a', 'b', 'c'],
                // Add error handling for tile loading
                errorTileCallback: (tile, error, stackTrace) {
                  print("Error loading tile: $error");
                },
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          // Top Control Panel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white.withOpacity(0.8),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(Icons.travel_explore, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chembur Landmarks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.my_location),
                        onPressed: () {
                          if (_position != null) {
                            _mapController.move(
                              LatLng(_position!.latitude, _position!.longitude),
                              _mapZoom,
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.list),
                        onPressed: _showPoiListView,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom Controls
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoomIn',
                  onPressed: () {
                    setState(() {
                      _mapZoom = (_mapZoom + 1).clamp(3.0, 18.0);
                      _mapController.move(_mapController.center, _mapZoom);
                    });
                  },
                  child: Icon(Icons.add),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoomOut',
                  onPressed: () {
                    setState(() {
                      _mapZoom = (_mapZoom - 1).clamp(3.0, 18.0);
                      _mapController.move(_mapController.center, _mapZoom);
                    });
                  },
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPoiListView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chembur Landmarks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Explore interesting places nearby',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: _poiList.length,
                  itemBuilder: (context, index) {
                    final poi = _poiList[index];
                    return PoiListItem(
                      poi: poi,
                      onTap: () {
                        Navigator.pop(context);
                        _selectPoi(index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class PoiListItem extends StatelessWidget {
  final PointOfInterest poi;
  final VoidCallback onTap;

  const PoiListItem({required this.poi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      _getIconForType(poi.type),
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Established ${poi.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'recreation':
        return Icons.golf_course;
      case 'wellness':
        return Icons.spa;
      case 'business':
        return Icons.business_center;
      case 'shopping':
        return Icons.shopping_bag;
      case 'landmark':
        return Icons.landscape;
      default:
        return Icons.place;
    }
  }
}

// ... existing code continues from above ...

class PoiDetailCard extends StatelessWidget {
  final PointOfInterest poi;

  const PoiDetailCard({required this.poi});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
        Center(
          child: Container(
            margin: EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poi.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getIconForType(poi.type),
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '${_capitalizeType(poi.type)} • Established ${poi.year}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_stories,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AI Insights',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Location info
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap to navigate to this location',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Description
              Text(
                'About ${poi.name}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  poi.description,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.directions),
                      label: Text('Directions'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Navigation would open here')),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.share),
                      label: Text('Share'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sharing would open here')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Additional info
              Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              _buildInfoRow(context, 'Type', _typeDescription(poi.type)),
              _buildInfoRow(
                  context, 'Best time to visit', _bestTimeToVisit(poi.type)),
              _buildInfoRow(context, 'Location', 'Mumbai, Maharashtra'),
              SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'recreation':
        return Icons.golf_course;
      case 'wellness':
        return Icons.spa;
      case 'business':
        return Icons.business_center;
      case 'shopping':
        return Icons.shopping_bag;
      case 'landmark':
        return Icons.landscape;
      default:
        return Icons.place;
    }
  }

  String _capitalizeType(String type) {
    return type.substring(0, 1).toUpperCase() + type.substring(1);
  }

  String _typeDescription(String type) {
    switch (type) {
      case 'recreation':
        return 'Sports and recreational facility';
      case 'wellness':
        return 'Health and wellness center';
      case 'business':
        return 'Commercial and business complex';
      case 'shopping':
        return 'Shopping and retail venue';
      case 'landmark':
        return 'Historical and cultural landmark';
      default:
        return 'Point of interest';
    }
  }

  String _bestTimeToVisit(String type) {
    switch (type) {
      case 'recreation':
        return 'Early morning or late afternoon';
      case 'wellness':
        return 'Weekday mornings, avoid weekends';
      case 'business':
        return 'Weekday afternoons or weekends';
      case 'shopping':
        return 'Weekday evenings or weekend mornings';
      case 'landmark':
        return 'Sunrise or sunset for best views';
      default:
        return 'Anytime during opening hours';
    }
  }
}

class PointOfInterest {
  final String name;
  final LatLng location;
  final String description;
  final String type;
  final int year;

  PointOfInterest(
      this.name, this.location, this.description, this.type, this.year);
}
