import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TripsPage extends StatefulWidget {
  @override
  _TripsPageState createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  List<TravelOption> _options = [];
  int _selectedIndex = 0;
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _searchRoutes() async {
    if (_startController.text.isEmpty || _destController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter both locations');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _options = [];
    });

    try {
      final response = await http.post(
        Uri.parse(
            'http://10.91.223.113:5004/api/travel-options'), // Updated IP address
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'origin': _startController.text,
          'destination': _destController.text,
          'modes': ['driving', 'walking', 'bus', 'train', 'flight']
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _options = (data['all_options'] as List)
              .map((opt) => TravelOption.fromJson(opt))
              .toList();
          _selectedIndex = _options.isNotEmpty ? 0 : -1;
        });
      } else {
        setState(() => _errorMessage =
            'Error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to connect: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Travel Options')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  decoration: InputDecoration(
                    labelText: 'From',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _destController,
                  decoration: InputDecoration(
                    labelText: 'To',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchRoutes,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Find Routes'),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          if (_options.isNotEmpty) _buildMap(),
          if (_options.isEmpty && !_isLoading)
            Expanded(
              child: Center(child: Text('No routes found')),
            ),
          if (_options.isNotEmpty) Expanded(child: _buildOptionsList()),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final option = _options[_selectedIndex];
    // Directly use the LatLng coordinates list
    final points = option.coordinates;

    return SizedBox(
      height: 300,
      child: FlutterMap(
        options: MapOptions(
          center: points.isNotEmpty ? points[0] : const LatLng(0, 0),
          zoom: points.length > 2 ? 10 : 5,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: Color(
                    int.parse(option.routeColor.replaceFirst('#', '0xff'))),
                strokeWidth: option.mode == 'flight' ? 2 : 4,
              ),
            ],
          ),
          MarkerLayer(
            markers: [
              if (points.isNotEmpty)
                Marker(
                  point: points.first,
                  builder: (ctx) =>
                      Icon(Icons.location_pin, color: Colors.green, size: 40),
                ),
              if (points.isNotEmpty)
                Marker(
                  point: points.last,
                  builder: (ctx) =>
                      Icon(Icons.location_pin, color: Colors.red, size: 40),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsList() {
    return ListView.builder(
      itemCount: _options.length,
      itemBuilder: (ctx, i) => Card(
        color: i == _selectedIndex
            ? Color(int.parse('0x11${_options[i].routeColor.substring(1)}'))
            : null,
        child: ListTile(
          leading:
              Text(_options[i].transportIcon, style: TextStyle(fontSize: 24)),
          title: Text(_options[i].mode.toUpperCase()),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_options[i].distance} km'),
              Text('${_options[i].duration} mins'),
              Text('₹${_options[i].fare}'),
            ],
          ),
          onTap: () => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }
}

class TravelOption {
  final String mode;
  final String transportIcon;
  final double distance;
  final int duration;
  final int fare;
  final String routeColor;
  final List<LatLng> coordinates;

  TravelOption({
    required this.mode,
    required this.transportIcon,
    required this.distance,
    required this.duration,
    required this.fare,
    required this.routeColor,
    required this.coordinates,
  });

  factory TravelOption.fromJson(Map<String, dynamic> json) {
    return TravelOption(
      mode: json['mode'],
      transportIcon: json['transport_icon'],
      distance: json['distance_km']?.toDouble() ?? 0.0,
      duration: json['duration_mins']?.toInt() ?? 0,
      fare: json['total_fare']?.toInt() ?? 0,
      routeColor: json['route_color'] ?? '#000000',
      coordinates: (json['coordinates'] as List).map((coord) {
        try {
          if (coord is List && coord.length >= 2) {
            return LatLng(
              (coord[0] as num).toDouble(),
              (coord[1] as num).toDouble(),
            );
          }
          return const LatLng(0.0, 0.0);
        } catch (e) {
          print('Coordinate parse error: $e');
          return const LatLng(0.0, 0.0);
        }
      }).toList(),
    );
  }
}
