import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationManagementPage extends StatefulWidget {
  const LocationManagementPage({super.key});

  @override
  _LocationManagementPageState createState() => _LocationManagementPageState();
}

class Room {
  Map<String, List<String>> sensorsByType; // Maps sensor type to list of sensor IDs
  Map<String, String> sensorValues; // Maps full sensor ID (e.g., "gas1") to its value
  String id;
  String? selectedSensorType;
  int level;

  Room({required this.id})
      : sensorsByType = {},
        sensorValues = {},
        selectedSensorType = null,
        level = 1;

  // Helper method to get next available sensor number for a type
  int getNextSensorNumber(String type) {
    if (!sensorsByType.containsKey(type)) {
      return 1;
    }
    List<String> sensors = sensorsByType[type] ?? [];
    if (sensors.isEmpty) return 1;
    
    List<int> numbers = sensors
        .map((s) => int.tryParse(s.replaceAll(type, '')) ?? 0)
        .toList();
    numbers.sort();
    return numbers.last + 1;
  }

  // Add a new sensor of given type
  void addSensor(String type) {
    if (!sensorsByType.containsKey(type)) {
      sensorsByType[type] = [];
    }
    int nextNum = getNextSensorNumber(type);
    String sensorId = '$type$nextNum';
    sensorsByType[type]!.add(sensorId);
    sensorValues[sensorId] = '';
  }

  // Remove a specific sensor
  void removeSensor(String sensorId) {
    String? type = sensorsByType.keys.firstWhere(
      (t) => sensorId.startsWith(t),
      orElse: () => '',
    );
    if (type.isNotEmpty) {
      sensorsByType[type]?.remove(sensorId);
      if (sensorsByType[type]?.isEmpty ?? false) {
        sensorsByType.remove(type);
      }
    }
    sensorValues.remove(sensorId);
  }
}

class _LocationManagementPageState extends State<LocationManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _locationNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final List<Room> _rooms = [];
  bool _isLoading = false;
  String? _existingLocationId;
  double? _latitude;
  double? _longitude;

  final List<String> _availableSensorTypes = [
    'temp',
    'humidity',
    'gas',
    'fire',
  ];

  @override
  void initState() {
    super.initState();
    assert(Set.from(_availableSensorTypes).length == _availableSensorTypes.length,
        'Duplicate sensors found in _availableSensorTypes');
    _loadExistingLocation();
    _addRoom();
    _getCurrentLocation();
  }

  void _loadExistingLocation() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await ref.once();

    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> locations = event.snapshot.value as Map;
      locations.forEach((key, value) {
        if (value['ID'] == userId) {
          setState(() {
            _existingLocationId = key;
            _locationNameController.text = value['name'] ?? '';
            _phoneNumberController.text = value['phone_number'] ?? '';
            _latitude = double.tryParse(value['lat'] ?? '');
            _longitude = double.tryParse(value['lon'] ?? '');
            _rooms.clear();

            // Load rooms
            value.forEach((roomKey, roomValue) {
              if (roomKey.startsWith('room')) {
                Room room = Room(id: roomKey);
                room.level = roomValue['level'] ?? 1;
                
                // Process each sensor in the room
                roomValue.forEach((sensorKey, sensorValue) {
                  if (sensorKey != 'ID') {
                    // Extract sensor type from key (e.g., 'gas' from 'gas1')
                    String type = _availableSensorTypes.firstWhere(
                      (t) => sensorKey.startsWith(t),
                      orElse: () => '',
                    );
                    
                    if (type.isNotEmpty) {
                      if (!room.sensorsByType.containsKey(type)) {
                        room.sensorsByType[type] = [];
                      }
                      room.sensorsByType[type]!.add(sensorKey);
                      room.sensorValues[sensorKey] = sensorValue.toString();
                    }
                  }
                });
                _rooms.add(room);
              }
            });
          });
        }
      });
    }
  }

  void _addRoom() {
    setState(() {
      Room newRoom = Room(id: 'room${_rooms.length + 1}');
      _rooms.add(newRoom);
    });
  }

  void _addSensor(Room room, String type) {
    setState(() {
      room.addSensor(type);
      room.selectedSensorType = null;
    });
  }

  void _removeRoom(int index) {
    setState(() {
      _rooms.removeAt(index);
      for (int i = 0; i < _rooms.length; i++) {
        _rooms[i].id = 'room${i + 1}';
      }
    });
  }

  Widget _buildSensorsList(Room room) {
    List<Widget> sensorWidgets = [];

    room.sensorsByType.forEach((type, sensorIds) {
      for (String sensorId in sensorIds) {
        sensorWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: room.sensorValues[sensorId],
                    decoration: InputDecoration(
                      labelText: '$sensorId Value',
                      border: const OutlineInputBorder(),
                      suffixText: type == 'fire' ? '(0/1)' : '',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (type == 'fire') {
                        if (value != '0' && value != '1') {
                          return 'Must be 0 or 1';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) {
                      room.sensorValues[sensorId] = value ?? '';
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => setState(() => room.removeSensor(sensorId)),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(children: sensorWidgets);
  }

  Widget _buildRoomCard(Room room, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Room ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeRoom(index),
                ),
              ],
            ),
            // Add level dropdown
            // DropdownButtonFormField<int>(
            //   decoration: InputDecoration(
            //     labelText: 'Room Level',
            //     border: OutlineInputBorder(),
            //   ),
            //   value: room.level,
            //   items: [1, 2, 3].map((int level) {
            //     return DropdownMenuItem<int>(
            //       value: level,
            //       child: Text('Level $level'),
            //     );
            //   }).toList(),
            //   onChanged: (int? newValue) {
            //     if (newValue != null) {
            //       setState(() => room.level = newValue);
            //     }
            //   },
            // ),
            const SizedBox(height: 15),
            _buildSensorsList(room),
            _buildAddSensorDropdown(room),
          ],
        ),
      ),
    );
  }

  Widget _buildAddSensorDropdown(Room room) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Add Sensor',
          border: OutlineInputBorder(),
        ),
        value: room.selectedSensorType,
        hint: const Text('Select a sensor type'),
        items: _availableSensorTypes.map((String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              room.selectedSensorType = newValue;
              _addSensor(room, newValue);
            });
          }
        },
      ),
    );
  }

  void _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      String locationId = _existingLocationId ?? 'location${DateTime.now().millisecondsSinceEpoch}';

      Map<String, dynamic> locationData = {
        'ID': userId,
        'name': _locationNameController.text,
        'phone_number': _phoneNumberController.text,
        'lat': _latitude.toString(),
        'lon': _longitude.toString(),
        'alarm': '0',
      };

      // Save rooms data
      for (var room in _rooms) {
        Map<String, dynamic> roomData = {
          'ID': room.level,
          'level': room.level,
        };
        // Add all sensor values
        roomData.addAll(room.sensorValues);
        locationData[room.id] = roomData;
      }

      DatabaseReference ref = FirebaseDatabase.instance.ref(locationId);
      await ref.set(locationData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved successfully')),
      );
      
      setState(() {
        _existingLocationId = locationId;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      print("Error getting location: $e");
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
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLocationDetails(),
                          const SizedBox(height: 20),
                          _buildRoomsList(),
                          const SizedBox(height: 20),
                          _buildAddRoomButton(),
                          const SizedBox(height: 20),
                          _buildSaveButton(),
                          if (_existingLocationId != null)
                            _buildLocationLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            _existingLocationId != null ? 'Edit Location' : 'Add Location',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showLocationInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetails() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _locationNameController,
            decoration: const InputDecoration(
              labelText: 'Location Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _phoneNumberController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a phone number' : null,
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.brown[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Coordinates',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[700],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_searching, size: 16, color: Colors.brown),
                    const SizedBox(width: 8),
                    Text('Latitude: ${_latitude?.toStringAsFixed(6) ?? "Loading..."}'),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_searching, size: 16, color: Colors.brown),
                    const SizedBox(width: 8),
                    Text('Longitude: ${_longitude?.toStringAsFixed(6) ?? "Loading..."}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList() {
    return Column(
      children: _rooms.asMap().entries.map((entry) {
        int index = entry.key;
        Room room = entry.value;
        return _buildRoomCard(room, index);
      }).toList(),
    );
  }

  Widget _buildAddRoomButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add Room'),
        
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[300],
          padding: const EdgeInsets.symmetric(vertical: 15),
          
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _addRoom,
      ),
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
        onPressed: _saveLocation,
        child: const Text(
          'Save Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color:Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.brown[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.brown[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.link, color: Colors.brown[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'https://smart-64616-default-rtdb.firebaseio.com/$_existingLocationId',
                style: TextStyle(
                  color: Colors.brown[700],
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.brown),
            SizedBox(width: 10),
            Text('Location Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('• Each user can have only one location'),
            _buildInfoItem('• Each location can have multiple rooms'),
            _buildInfoItem('• Each room can have multiple sensors of the same type'),
            _buildInfoItem('• Sensor IDs are automatically numbered (e.g., gas1, gas2)'),
            _buildInfoItem('• Fire sensor values must be 0 or 1'),
            _buildInfoItem('• Each room must have a level (1, 2, or 3)'),
            _buildInfoItem('• Location data will be stored in Firebase'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
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

    // Add a subtle gradient overlay
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(0.1),
        Colors.transparent,
      ],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(path, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}