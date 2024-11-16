import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartsavior2/utils/colors.dart';
import 'configuration/location_management.dart';

class CombinedSensorsPage extends StatefulWidget {
  final String userId;

  const CombinedSensorsPage({super.key, required this.userId});

  @override
  _CombinedSensorsPageState createState() => _CombinedSensorsPageState();
}

class _CombinedSensorsPageState extends State<CombinedSensorsPage> {
  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> filteredRooms = [];
  List<Map<String, dynamic>> tools = [];
  bool isLoading = true;
  String errorMessage = '';
  int selectedRoomIndex = 0;
  bool isExpanded = false;
  Map<String, dynamic>? configuration;
  String? factoryManagerId;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(() {
      _filterRooms(_searchController.text);
    });
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await fetchUserRole();
    await fetchData();
    await fetchTools();
  }

  Future<void> fetchUserRole() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          factoryManagerId = (userDoc.data() as Map<String, dynamic>)['factoryManagerId'];
        });
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  bool hasAccessToLocation(Map<String, dynamic> locationData) {
    return locationData['ID'] == widget.userId ||
           (factoryManagerId != null && locationData['ID'] == factoryManagerId);
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final url = Uri.parse('https://smart-64616-default-rtdb.firebaseio.com/.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        List<Map<String, dynamic>> fetchedRooms = [];

        data.forEach((locationKey, locationValue) {
          if (locationValue is Map<String, dynamic>) {
            if (hasAccessToLocation(locationValue)) {
              if (locationValue['configuration'] != null) {
                configuration = locationValue['configuration'];
              }

              locationValue.forEach((key, value) {
                if (key.startsWith('room') && value is Map<String, dynamic>) {
                  // Add room name if it exists, otherwise use a default name
                  String roomName = value['name'] ?? 'Room ${value['ID']}';
                  fetchedRooms.add({
                    ...value,
                    'name': roomName, // Ensure room name is included
                    'locationId': locationKey,
                    'locationName': locationValue['name'] ?? 'Unknown Location',
                    'avgTemp': calculateSensorAverage(value, 'temp'),
                    'avgHumidity': calculateSensorAverage(value, 'humidity'),
                    'avgGas': calculateSensorAverage(value, 'gas'),
                    'hasFire': value.entries
                        .where((e) => e.key.startsWith('fire'))
                        .any((e) => _parseDouble(e.value) == 1),
                  });
                }
              });
            }
          }
        });

        if (fetchedRooms.isEmpty) {
          throw Exception('No rooms found for this user');
        }

        setState(() {
          rooms = fetchedRooms;
          filteredRooms = fetchedRooms;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data. Please try again.';
      });
    }
  }


  // Helper function to calculate average of multiple sensors
  double calculateSensorAverage(Map<String, dynamic> room, String sensorType) {
    List<double> values = [];
    room.forEach((key, value) {
      if (key.startsWith(sensorType) && value != null) {
        double? parsedValue = _parseDouble(value);
        if (parsedValue != null) values.add(parsedValue);
      }
    });
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String getDangerLevel(int level) {
    switch (level) {
      case 1:
        return 'Safe';
      case 2:
        return 'Warning';
      case 3:
        return 'Danger';
      default:
        return 'Unknown';
    }
  }

  Color getDangerColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  

  Future<void> fetchTools() async {
    try {
      QuerySnapshot toolsSnapshot = await FirebaseFirestore.instance.collection('tools').get();
      setState(() {
        tools = toolsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    } catch (e) {
      print('Error fetching tools: $e');
    }
  }


///////////////////
 void _filterRooms(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredRooms = rooms;
      } else {
        filteredRooms = rooms.where((room) {
          final roomName = room['name']?.toString().toLowerCase() ?? '';
          final roomId = room['ID']?.toString().toLowerCase() ?? '';
          final locationName = room['locationName']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return roomName.contains(searchLower) || 
                 roomId.contains(searchLower) ||
                 locationName.contains(searchLower);
        }).toList();
      }
      _showSuggestions = _searchFocusNode.hasFocus && query.isNotEmpty;
    });
  }

  void _selectRoom(int index) {
    setState(() {
      selectedRoomIndex = index;
      _showSuggestions = false;
      _searchFocusNode.unfocus();
    });
  }

 
  Widget _buildSuggestionsList() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filteredRooms.length,
        itemBuilder: (context, index) {
          final room = filteredRooms[index];
          return ListTile(
            leading: const Icon(Icons.room),
            title: Text(room['name'] ?? 'Room ${room['ID']}'),
            subtitle: Text(room['locationName'] ?? ''),
            onTap: () {
              setState(() {
                selectedRoomIndex = rooms.indexOf(room);
                _showSuggestions = false;
                _searchController.text = room['name'] ?? 'Room ${room['ID']}';
              });
              _searchFocusNode.unfocus();
            },
          );
        },
      ),
    );
  }
///////////////////
 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors().primaryColor,
        title: const Text("Sensors", style: TextStyle(color: Colors.white),),
        centerTitle: true,
        leading: IconButton(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded, color: Colors.white,)),
      ),
      body: GestureDetector(
        onTap: () {
          _searchFocusNode.unfocus();
          setState(() {
            _showSuggestions = false;
          });
        },
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20,),
              _buildSearchBar(),
              if (!_showSuggestions) ...[
                const SizedBox(height: 10,),
                _buildRoomTabs(),
                const SizedBox(height: 10,),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildRoomDetails(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search rooms by name or number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_showSuggestions) _buildSuggestionsList(),
        ],
      ),
    );
  }

  Widget _buildRoomTabs() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (context, index) {
          final room = rooms[index];
          return _buildRoomTab(index, room['name'] ?? 'Room ${room['ID']}');
        },
      ),
    );
  }

  Widget _buildRoomDetails() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.redAccent, fontSize: 16),
        ),
      );
    }
    if (filteredRooms.isEmpty) {
      return Center(
        child: Text(
          'No rooms found for this user',
          style: TextStyle(color: Colors.grey[700], fontSize: 16),
        ),
      );
    }

    Map<String, dynamic> room = filteredRooms[selectedRoomIndex];
    int roomLevel = room['level'] ?? 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Room ${room['ID'] ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  room['locationName'] ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Danger Level Text
          Text(
            getDangerLevel(roomLevel),
            style: TextStyle(
              fontSize: 16,
              color: getDangerColor(roomLevel),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Level Indicator
          Container(

            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(30),
            child: SizedBox(
              height: 100,
              child: _buildLevelIndicator(roomLevel),
            ),
          ),
          const SizedBox(height: 16),

          // Sensor Grid
          _buildSensorGrid(room),

          // Expanded Content
          if (isExpanded) ...[
            Divider(
              color: Colors.grey[300],
              thickness: 1,
              height: 32,
            ),
            _buildThresholdInfo(room),
            const SizedBox(height: 12),
            _buildToolsList(room),
          ],
        ],
      ),
    );
  }


  Widget _buildSensorGrid(Map<String, dynamic> room) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: EdgeInsets.zero,
      children: [
        _buildSensorTile('Gas', room['avgGas'], Icons.local_fire_department),
        _buildSensorTile('Humidity', room['avgHumidity'], Icons.opacity),
        _buildSensorTile('Temperature', room['avgTemp'], Icons.thermostat),
        if (room['hasFire'])
          _buildSensorTile('Fire Detected', 'Yes', Icons.warning),
      ],
    );
  }

  Widget _buildSensorTile(String title, dynamic value, IconData icon) {
    double? parsedValue = _parseDouble(value);
    String displayValue = parsedValue != null ? '${parsedValue.toStringAsFixed(1)}%' : 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 46),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Sensors',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 48), // Placeholder to balance the back button
        ],
      ),
    );
  }

  Widget _buildRoomTab(int index, String roomName) {
    bool isSelected = index == selectedRoomIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRoomIndex = index;
          isExpanded = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors().primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey),
        ),
        child: Text(
          roomName,
          style: TextStyle(
            color: isSelected ? AppColors().secondaryColor : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelIndicator(int level) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 200,
            child: CircularProgressIndicator(
              value: level / 3,
              strokeWidth: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(getDangerColor(level)),
            ),
          ),
          Text(
            'Level $level',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdInfo(Map<String, dynamic> room) {
    if (configuration == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sensor Thresholds:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildThresholdRow('Temperature', room['avgTemp'],
            configuration!['thresholds']['temperature']['medium'],
            configuration!['thresholds']['temperature']['maximum']),
        _buildThresholdRow('Humidity', room['avgHumidity'],
            configuration!['thresholds']['humidity']['medium'],
            configuration!['thresholds']['humidity']['maximum']),
        _buildThresholdRow('Gas', room['avgGas'],
            configuration!['thresholds']['gas']['medium'],
            configuration!['thresholds']['gas']['maximum']),
      ],
    );
  }

 Widget _buildThresholdRow(String sensor, double value, double medium, double maximum) {
Color valueColor = value <= medium ? Colors.green
: value <= maximum ? Colors.orange : Colors.red;
return Padding(
padding: const EdgeInsets.symmetric(vertical: 4),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(sensor),
Text(
value.toStringAsFixed(1),
style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
),
Text('Med: $medium, Max: $maximum'),
],
),
);
}
Widget _buildToolsList(Map<String, dynamic> room) {
List<Map<String, dynamic>> roomTools = tools.where((tool) => tool['roomId'] == '${room['locationId']}-room${room['ID']}').toList();
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text('Tools:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 10),
ListView.builder(
shrinkWrap: true,
itemCount: roomTools.length,
itemBuilder: (context, index) {
Map<String, dynamic> tool = roomTools[index];
return ListTile(
title: Text(tool['name']),
subtitle: Text('Maintenance Date: ${_formatDate(tool['maintenanceDate'])}'),
trailing: Text('Expires: ${_formatDate(tool['expirationDate'])}'),
);
},
),
],
);
}
String _formatDate(dynamic timestamp) {
if (timestamp == null) return 'N/A';
if (timestamp is Timestamp) {
return timestamp.toDate().toString().split(' ')[0];
}
return 'N/A';
}
double _calculateRoomRisk(Map<String, dynamic> room) {
double temp = _parseDouble(room['temp']) ?? 0;
double gas = _parseDouble(room['gas']) ?? 0;
double humidity = _parseDouble(room['humidity']) ?? 0;
return (temp + gas + humidity) / 3;
}
double? _parseDouble(dynamic value) {
if (value == null) return null;
if (value is num) return value.toDouble();
if (value is String) return double.tryParse(value);
return null;
}
}