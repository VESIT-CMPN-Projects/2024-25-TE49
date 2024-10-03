import 'package:flutter/material.dart';
import 'chatbot.dart';
import 'account.dart';
import 'explore.dart';
import 'virtual.dart';

class RoutesPage extends StatefulWidget {
  @override
  _RoutesPageState createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final _startLocationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _travelTimeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedMode = 'car'; // Default mode
  List<TextEditingController> _stopControllers = [];

  @override
  void dispose() {
    _startLocationController.dispose();
    _destinationController.dispose();
    _travelTimeController.dispose();
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _travelTimeController.text = picked.format(context);
      });
    }
  }

  void _addStop() {
    setState(() {
      _stopControllers.add(TextEditingController());
    });
  }

  void _removeStop(int index) {
    setState(() {
      _stopControllers[index].dispose();
      _stopControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chart Your Journey'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField(
                  'Start Location',
                  _startLocationController,
                  'Enter start location',
                  'e.g., New York City',
                ),
                SizedBox(height: 20),
                _buildInputField(
                  'Your Destination',
                  _destinationController,
                  'Enter destination',
                  'e.g., Los Angeles',
                ),
                SizedBox(height: 20),
                _buildTimePicker(),
                SizedBox(height: 20),
                _buildStopsSection(),
                SizedBox(height: 20),
                Text(
                  'Select Mode of Transportation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                _buildModeSelection(),
                SizedBox(height: 40),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hintText,
    String errorText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: hintText,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $errorText';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time of Travel',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: _travelTimeController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.access_time),
          ),
          readOnly: true,
          onTap: () => _selectTime(context),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a time';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stops',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: _addStop,
              child: Text('Add Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        ..._stopControllers.asMap().entries.map((entry) {
          int idx = entry.key;
          var controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter stop ${idx + 1}',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.remove_circle_outline),
                  onPressed: () => _removeStop(idx),
                  color: Colors.red,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildModeSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildModeOption('car', Icons.directions_car),
        _buildModeOption('walk', Icons.directions_walk),
        _buildModeOption('bike', Icons.directions_bike),
        _buildModeOption('bus', Icons.directions_bus),
      ],
    );
  }

  Widget _buildModeOption(String mode, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _selectedMode == mode ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: _selectedMode == mode ? Colors.white : Colors.black,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() == true) {
            _showTripSummary();
          }
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          backgroundColor: Colors.blue,
        ),
        child: Text(
          'Submit',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  void _showTripSummary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Trip Summary'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('From: ${_startLocationController.text}'),
              Text('To: ${_destinationController.text}'),
              Text('Time: ${_travelTimeController.text}'),
              if (_stopControllers.isNotEmpty) ...[
                SizedBox(height: 10),
                Text('Stops:'),
                ..._stopControllers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var controller = entry.value;
                  return Text('  ${idx + 1}. ${controller.text}');
                }).toList(),
              ],
              SizedBox(height: 10),
              Text('Mode: $_selectedMode'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
            _buildNavItem('assets/logo1.png', 'Home', '/home'),
            _buildNavItem('assets/chatbot.png', 'WanderBot', '/chatbot'),
            _buildNavItem(Icons.luggage, 'Trips', '/routes', isSelected: true),
            _buildNavItem(Icons.vrpano_rounded, 'VR Tour', '/vr'),
            _buildNavItem(Icons.person_outline, 'Account', '/account'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(dynamic icon, String label, String route,
      {bool isSelected = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (route != '/routes') {
            switch (route) {
              case '/home':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ExplorePage()),
                );
                break;
              case '/chatbot':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ChatbotPage()),
                );
                break;
              case '/vr':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => VirtualPage()),
                );
                break;
              case '/account':
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AccountPage()),
                );
                break;
            }
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon is String
                ? Image.asset(icon, width: 24, height: 24)
                : Icon(icon,
                    color: isSelected ? Colors.blue : Colors.black, size: 24),
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
}
