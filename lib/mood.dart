import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MoodTravelPlanner extends StatefulWidget {
  @override
  _MoodTravelPlannerState createState() => _MoodTravelPlannerState();
}

class _MoodTravelPlannerState extends State<MoodTravelPlanner> {
  TextEditingController _moodController = TextEditingController();
  TextEditingController _daysController = TextEditingController(text: "3");
  String detectedMood = "";
  List<String> travelSuggestions = [];
  String itinerary = "";
  String selectedDestination = "";
  bool isLoading = false;
  bool isLoadingItinerary = false;

  final String moodApiUrl = "http://10.91.223.113:5004/api/mood-travel";
  final String itineraryApiUrl = "http://10.91.223.113:5004/api/mood-itinerary";

  // Expanded list of mood types for more interesting results
  final Map<String, IconData> moodIcons = {
    "adventurous": Icons.hiking,
    "relaxed": Icons.spa,
    "happy": Icons.sentiment_very_satisfied,
    "romantic": Icons.favorite,
    "curious": Icons.psychology,
    "energetic": Icons.bolt,
    "peaceful": Icons.self_improvement,
    "creative": Icons.palette,
    "cultural": Icons.museum,
    "reflective": Icons.auto_stories,
    "stressed": Icons.sentiment_very_dissatisfied,
    "excited": Icons.celebration,
    "spiritual": Icons.brightness_4,
    "nostalgic": Icons.photo_album,
    "luxurious": Icons.diamond,
  };

  // Expanded list of destinations for more variety
  final Map<String, List<String>> moodDestinations = {
    "adventurous": [
      "Rishikesh, India",
      "Machu Picchu, Peru",
      "Queenstown, New Zealand",
      "Costa Rica",
      "Patagonia, Argentina",
      "Swiss Alps, Switzerland",
      "Moab, Utah, USA",
      "Koh Phi Phi, Thailand"
    ],
    "relaxed": [
      "Bali, Indonesia",
      "Maldives",
      "Santorini, Greece",
      "Tulum, Mexico",
      "Sedona, Arizona, USA",
      "Kerala, India",
      "Provence, France",
      "Byron Bay, Australia"
    ],
    "happy": [
      "Barcelona, Spain",
      "Rio de Janeiro, Brazil",
      "Amsterdam, Netherlands",
      "New Orleans, USA",
      "Bangkok, Thailand",
      "Lisbon, Portugal",
      "Melbourne, Australia",
      "San Miguel de Allende, Mexico"
    ],
    "romantic": [
      "Paris, France",
      "Venice, Italy",
      "Kyoto, Japan",
      "Amalfi Coast, Italy",
      "Santorini, Greece",
      "Prague, Czech Republic",
      "Bora Bora, French Polynesia",
      "Charleston, South Carolina, USA"
    ],
    "curious": [
      "Tokyo, Japan",
      "Istanbul, Turkey",
      "Cairo, Egypt",
      "Marrakech, Morocco",
      "Mexico City, Mexico",
      "Jerusalem, Israel",
      "Berlin, Germany",
      "Cusco, Peru"
    ],
    "energetic": [
      "Las Vegas, USA",
      "Ibiza, Spain",
      "Berlin, Germany",
      "Miami, USA",
      "Singapore",
      "Seoul, South Korea",
      "Hong Kong",
      "New York City, USA"
    ],
    "peaceful": [
      "Kyoto, Japan",
      "Norwegian Fjords, Norway",
      "Lake District, UK",
      "Banff, Canada",
      "Ubud, Bali, Indonesia",
      "Kauai, Hawaii, USA",
      "Luang Prabang, Laos",
      "Hallstatt, Austria"
    ],
    "creative": [
      "Berlin, Germany",
      "Portland, Oregon, USA",
      "Barcelona, Spain",
      "Melbourne, Australia",
      "Copenhagen, Denmark",
      "Austin, Texas, USA",
      "Kyoto, Japan",
      "Mexico City, Mexico"
    ],
    "cultural": [
      "Rome, Italy",
      "Kyoto, Japan",
      "Istanbul, Turkey",
      "Varanasi, India",
      "Florence, Italy",
      "Fez, Morocco",
      "Jaipur, India",
      "Cusco, Peru"
    ],
    "reflective": [
      "Scottish Highlands, UK",
      "Sedona, Arizona, USA",
      "Big Sur, California, USA",
      "Norwegian Fjords, Norway",
      "Camino de Santiago, Spain",
      "Varanasi, India",
      "Bagan, Myanmar",
      "Joshua Tree, California, USA"
    ],
    "stressed": [
      "Bali, Indonesia",
      "Sedona, Arizona, USA",
      "Costa Rica",
      "Koh Samui, Thailand",
      "Amalfi Coast, Italy",
      "Blue Lagoon, Iceland",
      "Tulum, Mexico",
      "Hawaii, USA"
    ],
    "excited": [
      "Tokyo, Japan",
      "New York City, USA",
      "Las Vegas, USA",
      "Dubai, UAE",
      "London, UK",
      "Orlando, Florida, USA",
      "Barcelona, Spain",
      "Hong Kong"
    ],
    "spiritual": [
      "Bali, Indonesia",
      "Varanasi, India",
      "Camino de Santiago, Spain",
      "Kyoto, Japan",
      "Sedona, Arizona, USA",
      "Angkor Wat, Cambodia",
      "Kathmandu, Nepal",
      "Rishikesh, India"
    ],
    "nostalgic": [
      "Havana, Cuba",
      "New Orleans, USA",
      "Lisbon, Portugal",
      "Kyoto, Japan",
      "Rome, Italy",
      "Charleston, South Carolina, USA",
      "Venice, Italy",
      "Vienna, Austria"
    ],
    "luxurious": [
      "Monaco",
      "Dubai, UAE",
      "Santorini, Greece",
      "Maldives",
      "French Riviera, France",
      "Amalfi Coast, Italy",
      "Bora Bora, French Polynesia",
      "St. Moritz, Switzerland"
    ]
  };

  @override
  void initState() {
    super.initState();
    _daysController.text = "3"; // Default to 3 days
  }

  // Mock function to replace the API call for demo purposes
  Future<void> mockGetTravelSuggestions() async {
    setState(() {
      isLoading = true;
      // Reset previous results when searching again
      detectedMood = "";
      travelSuggestions = [];
      itinerary = "";
      selectedDestination = "";
    });

    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));

    // Analyze mood from text input
    String text = _moodController.text.toLowerCase();
    String mood = "happy"; // Default mood

    // Simple mood detection logic
    if (text.contains("stress") ||
        text.contains("tired") ||
        text.contains("overwhelm")) {
      mood = "stressed";
    } else if (text.contains("adventur") ||
        text.contains("excit") ||
        text.contains("thrill")) {
      mood = "adventurous";
    } else if (text.contains("relax") ||
        text.contains("calm") ||
        text.contains("peace")) {
      mood = "peaceful";
    } else if (text.contains("love") ||
        text.contains("romantic") ||
        text.contains("partner")) {
      mood = "romantic";
    } else if (text.contains("curious") ||
        text.contains("learn") ||
        text.contains("interest")) {
      mood = "curious";
    } else if (text.contains("energy") ||
        text.contains("active") ||
        text.contains("fun")) {
      mood = "energetic";
    } else if (text.contains("creat") ||
        text.contains("inspir") ||
        text.contains("art")) {
      mood = "creative";
    } else if (text.contains("culture") ||
        text.contains("history") ||
        text.contains("tradition")) {
      mood = "cultural";
    } else if (text.contains("think") ||
        text.contains("reflect") ||
        text.contains("quiet")) {
      mood = "reflective";
    } else if (text.contains("luxury") ||
        text.contains("pamper") ||
        text.contains("indulge")) {
      mood = "luxurious";
    } else if (text.contains("nostalg") ||
        text.contains("memor") ||
        text.contains("past")) {
      mood = "nostalgic";
    } else if (text.contains("spirit") ||
        text.contains("soul") ||
        text.contains("meditat")) {
      mood = "spiritual";
    } else if (text.contains("happy") ||
        text.contains("joy") ||
        text.contains("good")) {
      mood = "happy";
    }

    setState(() {
      detectedMood = mood;
      // Get destinations based on the detected mood
      travelSuggestions = moodDestinations[mood] ?? [];
    });

    setState(() => isLoading = false);
  }

  Future<void> getTravelSuggestions() async {
    // For demo purposes, using mock function instead of real API call
    /*await mockGetTravelSuggestions();*/

    setState(() {
      isLoading = true;
      // Reset previous results when searching again
      detectedMood = "";
      travelSuggestions = [];
      itinerary = "";
      selectedDestination = "";
    });

    try {
      final response = await http.post(
        Uri.parse(moodApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": _moodController.text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          detectedMood = data["mood"];
          travelSuggestions = List<String>.from(data["destinations"]);
        });
      } else {
        setState(() {
          detectedMood = "Error detecting mood";
          travelSuggestions = [];
        });
        _showErrorSnackBar("Failed to get destinations. Please try again.");
      }
    } catch (e) {
      setState(() {
        detectedMood = "Server error";
        travelSuggestions = [];
      });
      _showErrorSnackBar("Server error: $e");
    }

    setState(() => isLoading = false);
  }

  // Mock function to replace the API call for demo purposes
  Future<void> mockGetItinerary(String destination) async {
    int days = int.tryParse(_daysController.text) ?? 3;

    setState(() {
      isLoadingItinerary = true;
      selectedDestination = destination;
      itinerary = ""; // Clear previous itinerary
    });

    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));

    // Generate a sample itinerary based on the destination and mood
    String sampleItinerary =
        """## $days-Day $detectedMood Itinerary for $destination

**Day 1: Arrival & Exploration**

**Morning**
- 8:00 AM - 9:30 AM: Arrive at your accommodation and settle in
- 10:00 AM - 12:00 PM: Orientation walk around the main area to get your bearings

**Afternoon**
- 12:30 PM - 2:00 PM: Enjoy a local lunch at a popular restaurant
- 2:30 PM - 5:00 PM: Visit the main attraction that matches your $detectedMood mood

**Evening**
- 6:00 PM - 7:30 PM: Relax and freshen up at your accommodation
- 8:00 PM - 10:00 PM: Dinner at a restaurant with local atmosphere

**Day 2: Immersive Experiences**

**Morning**
- 7:30 AM - 8:30 AM: Morning activity suited to your $detectedMood energy
- 9:00 AM - 12:00 PM: Guided tour of a signature location in $destination

**Afternoon**
- 12:30 PM - 2:00 PM: Lunch at a scenic spot
- 2:30 PM - 5:00 PM: Engage in a $detectedMood activity specific to $destination

**Evening**
- 6:00 PM - 8:00 PM: Special dining experience
- 8:30 PM - 10:00 PM: Evening entertainment suited to your mood
""";

    // Add more days based on the selected number of days
    if (days >= 3) {
      sampleItinerary += """

**Day 3: Deep Dive**

**Morning**
- 8:00 AM - 9:00 AM: Breakfast at a local favorite spot
- 9:30 AM - 12:00 PM: Visit to an off-the-beaten-path location

**Afternoon**
- 12:30 PM - 2:00 PM: Relaxed lunch
- 2:30 PM - 5:00 PM: Activity tailored to your $detectedMood preferences

**Evening**
- 6:00 PM - 7:30 PM: Rest and reflection time
- 8:00 PM - 10:00 PM: Farewell dinner experience
""";
    }

    if (days >= 4) {
      sampleItinerary += """

**Day 4: Adventure Extension**

**Morning**
- 7:30 AM - 8:30 AM: Early morning nature experience
- 9:00 AM - 12:00 PM: Exploration of natural wonders near $destination

**Afternoon**
- 12:30 PM - 2:00 PM: Picnic lunch in a scenic location
- 2:30 PM - 5:00 PM: Outdoor activity suited to your $detectedMood preferences

**Evening**
- 6:00 PM - 8:00 PM: Dinner at a highly-rated local establishment
- 8:30 PM - 10:00 PM: Cultural evening entertainment
""";
    }

    if (days >= 5) {
      sampleItinerary += """

**Day 5: Cultural Immersion**

**Morning**
- 8:00 AM - 9:30 AM: Visit to a local market or community space
- 10:00 AM - 12:00 PM: Historical or cultural tour relevant to $destination

**Afternoon**
- 12:30 PM - 2:00 PM: Authentic local cuisine experience
- 2:30 PM - 5:00 PM: Workshop or class to learn a local craft or skill

**Evening**
- 6:00 PM - 7:30 PM: Time to pack and prepare for departure
- 8:00 PM - 10:00 PM: Final celebratory dinner
""";
    }

    setState(() {
      itinerary = sampleItinerary;
      isLoadingItinerary = false;
    });
  }

  Future<void> getItinerary(String destination) async {
    // For demo purposes, using mock function instead of real API call
    /*await mockGetItinerary(destination);*/

    int days = int.tryParse(_daysController.text) ?? 3;

    setState(() {
      isLoadingItinerary = true;
      selectedDestination = destination;
      itinerary = ""; // Clear previous itinerary
    });

    try {
      final response = await http.post(
        Uri.parse(itineraryApiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mood": detectedMood,
          "destination": destination,
          "days": days // Use the user-selected number of days
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Received itinerary: ${data["itinerary"]}");
        setState(() {
          // Format the itinerary by removing Markdown syntax
          String formattedItinerary =
              data["itinerary"] ?? "No itinerary found.";
          itinerary = formattedItinerary;
        });
      } else {
        setState(() {
          itinerary =
              "Error fetching itinerary. Status code: ${response.statusCode}";
        });
        _showErrorSnackBar("Failed to get itinerary. Please try again.");
      }
    } catch (e) {
      setState(() {
        itinerary = "Server error.";
      });
      _showErrorSnackBar("Server error: $e");
    }

    setState(() => isLoadingItinerary = false);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Format the itinerary text by parsing sections
  Widget buildFormattedItinerary(String itineraryText) {
    // Parse the raw text into structured sections
    final sections = parseItinerarySections(itineraryText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.isTitle)
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Text(
                  section.content.replaceAll(RegExp(r'[#*]+'), '').trim(),
                  style: TextStyle(
                    fontSize: section.level == 1 ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              )
            else if (section.isSubheading)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
                child: Text(
                  section.content.replaceAll(RegExp(r'[#*]+'), '').trim(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              )
            else if (section.isTimeBlock)
              Padding(
                padding:
                    const EdgeInsets.only(top: 8.0, bottom: 4.0, left: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        section.content.replaceAll(RegExp(r'[#*]+'), '').trim(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                child: Text(
                  section.content.replaceAll(RegExp(r'[#*]+'), '').trim(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            if (section.isTitle || section.isSubheading)
              Divider(
                  color: section.isTitle
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                  height: 16),
          ],
        );
      }).toList(),
    );
  }

  // Parse the itinerary into structured sections
  List<ItinerarySection> parseItinerarySections(String text) {
    final List<ItinerarySection> sections = [];
    final lines = text.split('\n');

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Check for different types of sections
      if (line.startsWith('## ')) {
        sections.add(ItinerarySection(line, isTitle: true, level: 1));
      } else if (line.startsWith('**Day')) {
        sections.add(ItinerarySection(line, isTitle: true, level: 2));
      } else if (line.startsWith('**Morning') ||
          line.startsWith('**Afternoon') ||
          line.startsWith('**Evening')) {
        sections.add(ItinerarySection(line, isSubheading: true));
      } else if (line.contains('AM') &&
          line.contains('PM') &&
          line.contains(':')) {
        sections.add(ItinerarySection(line, isTimeBlock: true));
      } else {
        sections.add(ItinerarySection(line));
      }
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  "AI Mood Travel Planner",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=500&auto=format&fit=crop",
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mood Input Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "How are you feeling today?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            TextField(
                              controller: _moodController,
                              decoration: InputDecoration(
                                labelText: "Describe your mood",
                                hintText:
                                    "I'm feeling excited and energetic...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                prefixIcon: Icon(Icons.mood),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              maxLines: 2,
                            ),
                            SizedBox(height: 16),

                            // Add number of days selector
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _daysController,
                                    decoration: InputDecoration(
                                      labelText: "Number of Days",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      prefixIcon: Icon(Icons.calendar_today),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Days increment/decrement buttons
                                Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        int currentDays = int.tryParse(
                                                _daysController.text) ??
                                            3;
                                        if (currentDays < 7) {
                                          setState(() {
                                            _daysController.text =
                                                (currentDays + 1).toString();
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Icon(Icons.add,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    InkWell(
                                      onTap: () {
                                        int currentDays = int.tryParse(
                                                _daysController.text) ??
                                            3;
                                        if (currentDays > 1) {
                                          setState(() {
                                            _daysController.text =
                                                (currentDays - 1).toString();
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Icon(Icons.remove,
                                            color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    isLoading ? null : getTravelSuggestions,
                                icon: Icon(Icons.travel_explore),
                                label: isLoading
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text("Finding Destinations..."),
                                        ],
                                      )
                                    : Text("Find Destinations"),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Mood Detection Result
                    if (detectedMood.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    moodIcons[detectedMood] ?? Icons.mood,
                                    size: 28,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  SizedBox(width: 8),
                                  // Fix for overflow by using Expanded widget to contain the text
                                  Expanded(
                                    child: Text(
                                      "Detected Mood: ${detectedMood.toUpperCase()}",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      // Ensure text doesn't overflow
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(height: 24),
                              Text(
                                "Recommended Destinations",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Destination List
            if (travelSuggestions.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final destination = travelSuggestions[index];
                      final isSelected = selectedDestination == destination;

                      return Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelected
                              ? BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.all(16),
                              title: Text(
                                destination,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: ElevatedButton.icon(
                                onPressed: isLoadingItinerary &&
                                        selectedDestination == destination
                                    ? null
                                    : () => getItinerary(destination),
                                icon: Icon(Icons.explore),
                                label: isLoadingItinerary &&
                                        selectedDestination == destination
                                    ? SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text("Get Itinerary"),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                              onTap: () => getItinerary(destination),
                            ),
                            if (isSelected && itinerary.isNotEmpty) ...[
                              Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: buildFormattedItinerary(itinerary),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                    childCount: travelSuggestions.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper class to represent different sections of the itinerary
class ItinerarySection {
  final String content;
  final bool isTitle;
  final bool isSubheading;
  final bool isTimeBlock;
  final int level;

  ItinerarySection(
    this.content, {
    this.isTitle = false,
    this.isSubheading = false,
    this.isTimeBlock = false,
    this.level = 0,
  });
}
