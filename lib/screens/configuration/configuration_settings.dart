import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ConfigurationSettingsPage extends StatefulWidget {
  final String userId;
  const ConfigurationSettingsPage({super.key, required this.userId});

  @override
  _ConfigurationSettingsPageState createState() => _ConfigurationSettingsPageState();
}

class _ConfigurationSettingsPageState extends State<ConfigurationSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _database = FirebaseDatabase.instance.ref();
  
  // Map to store room configurations
  final Map<String, Map<String, dynamic>> _roomConfigs = {};
  // List to store selected rooms for bulk configuration
  final Set<String> _selectedRooms = {};
  // List to store all rooms in the location
  List<String> _rooms = [];
  
  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final snapshot = await _database.get();
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        data.forEach((locationKey, locationData) {
          if (locationData is Map) {
            final locationMap = Map<String, dynamic>.from(locationData);
            if (locationMap['ID'] == widget.userId) {
              // Find all rooms in this location
              _rooms = locationMap.keys
                  .where((key) => key.startsWith('room'))
                  .toList();
              
              // Initialize configurations for each room
              for (String room in _rooms) {
                _roomConfigs[room] = {
                  'priorities': {
                    'temperature': 2,
                    'humidity': 2,
                    'gas': 2,
                  },
                  'thresholds': {
                    'temperature': {'medium': 25, 'maximum': 35},
                    'humidity': {'medium': 60, 'maximum': 80},
                    'gas': {'medium': 30, 'maximum': 50},
                  }
                };
              }
              setState(() {});
            }
          }
        });
      }
    } catch (e) {
      print('Error loading rooms: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: TopHillPainter(),
              size: Size(MediaQuery.of(context).size.width, 250),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRoomSelection(),
                          const SizedBox(height: 20),
                          _buildConfigurationCards(),
                          const SizedBox(height: 30),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Text(
            'Room Configuration',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Rooms for Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _rooms.map((room) {
                return FilterChip(
                  label: Text(room),
                  selected: _selectedRooms.contains(room),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedRooms.add(room);
                      } else {
                        _selectedRooms.remove(room);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCards() {
    if (_selectedRooms.isEmpty) {
      return Center(
        child: Text('Select rooms to configure',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: _selectedRooms.map((room) => 
        _buildRoomConfigCard(room)
      ).toList(),
    );
  }

  Widget _buildRoomConfigCard(String room) {
    final config = _roomConfigs[room]!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildPrioritySection(room, config),
            const SizedBox(height: 16),
            _buildThresholdSection(room, config),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySection(String room, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priorities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildPrioritySlider('Temperature', room, 'temperature', config),
        _buildPrioritySlider('Humidity', room, 'humidity', config),
        _buildPrioritySlider('Gas', room, 'gas', config),
      ],
    );
  }

  Widget _buildPrioritySlider(String label, String room, String field, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label Priority'),
        Slider(
          value: config['priorities'][field].toDouble(),
          min: 1,
          max: 3,
          divisions: 2,
          label: config['priorities'][field].toString(),
          onChanged: (value) {
            setState(() {
              _roomConfigs[room]!['priorities'][field] = value.round();
            });
          },
        ),
      ],
    );
  }

  Widget _buildThresholdSection(String room, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thresholds', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildThresholdFields('Temperature', room, 'temperature', '°C', config),
        _buildThresholdFields('Humidity', room, 'humidity', '%', config),
        _buildThresholdFields('Gas', room, 'gas', 'ppm', config),
      ],
    );
  }

  Widget _buildThresholdFields(String label, String room, String field, String unit, Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: config['thresholds'][field]['medium'].toString(),
                decoration: InputDecoration(
                  labelText: 'Medium ($unit)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _roomConfigs[room]!['thresholds'][field]['medium'] = double.tryParse(value) ?? 0;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: config['thresholds'][field]['maximum'].toString(),
                decoration: InputDecoration(
                  labelText: 'Maximum ($unit)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _roomConfigs[room]!['thresholds'][field]['maximum'] = double.tryParse(value) ?? 0;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[700],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _saveConfiguration,
        child: const Text(
          'Save Configuration',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  void _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final snapshot = await _database.get();
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        
        data.forEach((locationKey, locationData) {
          if (locationData is Map) {
            final locationMap = Map<String, dynamic>.from(locationData);
            if (locationMap['ID'] == widget.userId) {
              // Update configurations for selected rooms
              for (String room in _selectedRooms) {
                _database.child(locationKey).child(room).update({
                  'configuration': _roomConfigs[room],
                });
              }
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving configuration: $e')),
      );
    }
  }
}

class TopHillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[300]!
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.2,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}