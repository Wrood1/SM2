  import 'package:flutter/material.dart';
  import 'package:firebase_database/firebase_database.dart';
  import 'package:smartsavior2/utils/colors.dart';


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
    // Selected room from dropdown
    String? _selectedRoom;
    // Map to store room IDs and their names
    final Map<String, String> _roomNames = {};
    // List to store all rooms in the location
    final List<String> _rooms = [];

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
                locationMap.forEach((key, value) {
                  if (key.startsWith('room') && value is Map) {
                    _rooms.add(key);
                    _roomNames[key] = (value['name'] as String?) ?? key;

                    _roomConfigs[key] = {
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
                });
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
        backgroundColor: AppColors().backgroundColor,
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
                  const SizedBox(height: 40,),
                  Text(
                    '${_rooms.length} Rooms Available',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 50,),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRoomList(),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: _buildSaveButton(),
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
              icon: const Icon(Icons.arrow_back, color: Colors.white,),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            const Text(
              'Room Configuration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildRoomList() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ..._rooms.map((room) => _buildExpandableRoomConfig(room)),
        ],
      );
    }

    Widget _buildExpandableRoomConfig(String room) {
      final config = _roomConfigs[room]!;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: ExpansionTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                _roomNames[room] ?? room,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors().primaryColor,
                ),
              ),
              children: [
                Divider(thickness: 1, color: AppColors().primaryColor.withOpacity(0.5)),
                _buildPrioritySection(room, config),
                const SizedBox(height: 16),
                _buildThresholdSection(room, config),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildPrioritySection(String room, Map<String, dynamic> config) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Priorities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            activeColor: AppColors().primaryColor,
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
          const SizedBox(height: 20,),
          _buildThresholdFields('Temperature', room, 'temperature', '°C', config),
          const SizedBox(height: 20,),
          _buildThresholdFields('Humidity', room, 'humidity', '%', config),
          const SizedBox(height: 20,),
          _buildThresholdFields('Gas', room, 'gas', 'ppm', config),
        ],
      );
    }

    Widget _buildThresholdFields(String label, String room, String field, String unit, Map<String, dynamic> config) {
      return Row(
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
            ),
          ),
        ],
      );
    }

    Widget _buildSaveButton() {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors().primaryColor,
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
      if (_selectedRoom == null) return;

      try {
        final snapshot = await _database.get();
        if (snapshot.value != null) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);

          data.forEach((locationKey, locationData) {
            if (locationData is Map) {
              final locationMap = Map<String, dynamic>.from(locationData);
              if (locationMap['ID'] == widget.userId) {
                _database.child(locationKey).child(_selectedRoom!).update({
                  'configuration': _roomConfigs[_selectedRoom!],
                });
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
        ..color = AppColors().primaryColor
        ..style = PaintingStyle.fill;
      final path = Path();

      path.lineTo(0, size.height * 0.6);
      path.quadraticBezierTo(size.width * 0.5, size.height, size.width, size.height * 0.6);
      path.lineTo(size.width, 0);
      path.close();

      canvas.drawPath(path, paint);
    }

    @override
    bool shouldRepaint(CustomPainter oldDelegate) => false;
  }
