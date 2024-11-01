import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class NotificationsPage extends StatefulWidget {
  final String userId;

  const NotificationsPage({
    Key? key, 
    required this.userId,
  }) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool isLoading = true;
  String? factoryManagerId;
  Map<String, dynamic>? userLocation;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await fetchUserRole();
    await fetchLocationData();
  }

  bool hasAccessToLocation(Map<String, dynamic> locationData) {
    // If the user is the factory manager of this location
    if (widget.userId == locationData['ID']) {
      return true;
    }
    
    // If the user has this location's manager as their factoryManagerId
    if (factoryManagerId != null && locationData['ID'] == factoryManagerId) {
      return true;
    }
    
    return false;
  }

  Future<void> fetchUserRole() async {
    try {
      // Get user data from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        setState(() {
          // Using the correct field name 'factoryManagerId' instead of 'factoryManagerID'
          factoryManagerId = userData?['factoryManagerId'] as String?;
          print('Factory Manager Id: $factoryManagerId'); // Debug print
        });
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  Future<void> fetchLocationData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final url = Uri.parse('https://smart-64616-default-rtdb.firebaseio.com/.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Debug prints
        print('User ID: ${widget.userId}');
        print('Factory Manager Id: $factoryManagerId');
        
        // Iterate through the locations (location1, location2, etc.)
        for (var entry in data.entries) {
          if (entry.value is Map<String, dynamic>) {
            final locationData = entry.value as Map<String, dynamic>;
            print('Checking location: ${entry.key}');
            print('Location ID: ${locationData['ID']}');
            
            if (hasAccessToLocation(locationData)) {
              print('Access granted to location: ${entry.key}');
              setState(() {
                userLocation = {
                  ...locationData,
                  'key': entry.key,
                };
              });
              break; // Exit the loop once we find the matching location
            } else {
              print('Access denied to location: ${entry.key}');
            }
          }
        }

        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load location data');
      }
    } catch (e) {
      print('Error fetching location data: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data. Please try again.';
      });
    }
  }
  List<Map<String, dynamic>> _buildNotificationsList(Map<String, dynamic> locationData) {
    final notifications = <Map<String, dynamic>>[];
    
    // Get list of rooms with issues
    final affectedRooms = _getAffectedRooms(locationData);
    
    // Process rooms based on their danger levels
    final Map<int, List<String>> roomsByLevel = {
      2: [], // Medium danger
      3: [], // Serious danger
    };

    affectedRooms.forEach((roomInfo) {
      final level = int.tryParse(roomInfo['level'].toString()) ?? 0;
      if (level == 2 || level == 3) {
        roomsByLevel[level]!.add(roomInfo['name']);
      }
    });

    // Create notifications based on danger levels
    if (roomsByLevel[3]!.isNotEmpty) {
      notifications.add({
        'type': 'serious',
        'title': '${locationData['name']} - Serious Danger',
        'message': 'Serious danger detected in rooms: ${roomsByLevel[3]!.join(", ")}',
        'timestamp': DateTime.now().toString(),
        'level': 3,
      });
    }

    if (roomsByLevel[2]!.isNotEmpty) {
      notifications.add({
        'type': 'medium',
        'title': '${locationData['name']} - Medium Risk',
        'message': 'Medium risk detected in rooms: ${roomsByLevel[2]!.join(", ")}',
        'timestamp': DateTime.now().toString(),
        'level': 2,
      });
    }

    notifications.sort((a, b) {
      final levelCompare = (b['level'] ?? 0).compareTo(a['level'] ?? 0);
      if (levelCompare != 0) return levelCompare;
      return b['timestamp'].compareTo(a['timestamp']);
    });

    return notifications;
  }

  List<Map<String, dynamic>> _getAffectedRooms(Map<String, dynamic> locationMap) {
    final affectedRooms = <Map<String, dynamic>>[];
    final configuration = locationMap['configuration'] as Map<String, dynamic>?;
    
    locationMap.forEach((key, value) {
      if (key.startsWith('room') && value is Map) {
        final roomMap = Map<String, dynamic>.from(value);
        if (_shouldTriggerAlarm(roomMap, configuration)) {
          affectedRooms.add({
            'name': key,
            'level': roomMap['level'] ?? '0',
          });
        }
      }
    });

    return affectedRooms;
  }

  bool _shouldTriggerAlarm(Map<String, dynamic> roomData, Map<String, dynamic>? config) {
    final thresholds = config?['thresholds'] as Map<String, dynamic>? ?? {};
    final priorities = config?['priorities'] as Map<String, dynamic>? ?? {};
    
    // Check for fire sensors
    if (roomData['fire1'] == '1' || roomData['fire1'] == 1 ||
        roomData['fire2'] == '1' || roomData['fire2'] == 1) {
      return true;
    }
    
    // Check for gas level
    final gasLevel = num.tryParse(roomData['gas1']?.toString() ?? '0') ?? 0;
    final gasThresholds = thresholds['gas'] as Map<String, dynamic>? ?? 
        {'medium': 30, 'maximum': 50};
    if (gasLevel > gasThresholds['medium']) {
      return true;
    }
    
    // Check for temperature
    final temp1 = num.tryParse(roomData['temp1']?.toString() ?? '0') ?? 0;
    final temp2 = num.tryParse(roomData['temp2']?.toString() ?? '0') ?? 0;
    final tempThresholds = thresholds['temperature'] as Map<String, dynamic>? ?? 
        {'medium': 25, 'maximum': 35};
    if (temp1 > tempThresholds['medium'] || temp2 > tempThresholds['medium']) {
      return true;
    }
    
    // Check for humidity
    final humidity1 = num.tryParse(roomData['humidity1']?.toString() ?? '0') ?? 0;
    final humidity2 = num.tryParse(roomData['humidity2']?.toString() ?? '0') ?? 0;
    final humidityThresholds = thresholds['humidity'] as Map<String, dynamic>? ?? 
        {'medium': 60, 'maximum': 80};
    if (humidity1 > humidityThresholds['medium'] || humidity2 > humidityThresholds['medium']) {
      return true;
    }
    
    return false;
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final Color backgroundColor;
    final Color iconColor;
    final IconData iconData;

    switch (notification['level']) {
      case 3:
        backgroundColor = Colors.red[100]!;
        iconColor = Colors.red;
        iconData = Icons.warning;
        break;
      case 2:
        backgroundColor = Colors.orange[100]!;
        iconColor = Colors.orange;
        iconData = Icons.warning_amber;
        break;
      default:
        backgroundColor = Colors.white;
        iconColor = Colors.brown;
        iconData = Icons.notifications;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: ListTile(
        leading: Icon(
          iconData,
          color: iconColor,
          size: 28,
        ),
        title: Text(
          notification['title'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'],
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification['timestamp'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.brown[300],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : userLocation == null
                  ? const Center(child: Text('No access to any location'))
                  : ListView.builder(
                      itemCount: _buildNotificationsList(userLocation!).length,
                      itemBuilder: (context, index) {
                        final notifications = _buildNotificationsList(userLocation!);
                        return _buildNotificationCard(notifications[index]);
                      },
                    ),
    );
  }
}