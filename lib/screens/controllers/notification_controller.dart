// notification_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notification_model.dart';
class NotificationController {
  final String userId;
  String? factoryManagerId;

  NotificationController({required this.userId});

  Future<void> fetchUserRole() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        factoryManagerId = userData?['factoryManagerId']?.toString();
      }
    } catch (e) {
      print('Error fetching user role: $e');
      throw Exception('Failed to fetch user role');
    }
  }

  Future<LocationModel?> fetchLocationData() async {
    try {
      final url = Uri.parse('https://smart-64616-default-rtdb.firebaseio.com/.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        for (var entry in data.entries) {
          if (entry.value is Map<String, dynamic>) {
            final locationData = entry.value as Map<String, dynamic>;
            
            if (hasAccessToLocation(locationData)) {
              return LocationModel.fromMap(locationData, entry.key);
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching location data: $e');
      throw Exception('Failed to fetch location data');
    }
  }

  bool hasAccessToLocation(Map<String, dynamic> locationData) {
    // Convert IDs to strings for comparison
    String locationId = locationData['ID']?.toString() ?? '';
    String currentUserId = userId.toString();
    String? currentManagerId = factoryManagerId?.toString();

    return currentUserId == locationId || 
           (currentManagerId != null && locationId == currentManagerId);
  }

  List<NotificationModel> buildNotificationsList(LocationModel location) {
    final notifications = <NotificationModel>[];
    final affectedRooms = _getAffectedRooms(location);
    
    final Map<int, List<String>> roomsByLevel = {
      2: [],
      3: [],
    };

    for (var room in affectedRooms) {
      final level = int.tryParse(room.level) ?? 0;
      if (level == 2 || level == 3) {
        roomsByLevel[level]!.add(room.name);
      }
    }

    if (roomsByLevel[3]!.isNotEmpty) {
      notifications.add(
        NotificationModel(
          type: 'serious',
          title: '${location.name} - Serious Danger',
          message: 'Serious danger detected in rooms: ${roomsByLevel[3]!.join(", ")}',
          timestamp: DateTime.now().toString(),
          level: 3,
        ),
      );
    }

    if (roomsByLevel[2]!.isNotEmpty) {
      notifications.add(
        NotificationModel(
          type: 'medium',
          title: '${location.name} - Medium Risk',
          message: 'Medium risk detected in rooms: ${roomsByLevel[2]!.join(", ")}',
          timestamp: DateTime.now().toString(),
          level: 2,
        ),
      );
    }

    notifications.sort((a, b) {
      final levelCompare = b.level.compareTo(a.level);
      if (levelCompare != 0) return levelCompare;
      return b.timestamp.compareTo(a.timestamp);
    });

    return notifications;
  }

  List<RoomModel> _getAffectedRooms(LocationModel location) {
    final affectedRooms = <RoomModel>[];
    
    location.rooms.forEach((key, value) {
      if (value is Map) {
        final roomMap = Map<String, dynamic>.from(value);
        if (_shouldTriggerAlarm(roomMap, location.configuration)) {
          affectedRooms.add(RoomModel(
            name: key,
            level: roomMap['level']?.toString() ?? '0',
          ));
        }
      }
    });

    return affectedRooms;
  }

  bool _shouldTriggerAlarm(Map<String, dynamic> roomData, Map<String, dynamic> config) {
    final thresholds = config['thresholds'] as Map<String, dynamic>? ?? {};
    
    // Convert fire sensor values to string for comparison
    if (roomData['fire1']?.toString() == '1' || 
        roomData['fire2']?.toString() == '1') {
      return true;
    }
    
    final gasLevel = num.tryParse(roomData['gas1']?.toString() ?? '0') ?? 0;
    final gasThresholds = thresholds['gas'] as Map<String, dynamic>? ?? 
        {'medium': 30, 'maximum': 50};
    if (gasLevel > (gasThresholds['medium'] ?? 30)) {
      return true;
    }
    
    final temp1 = num.tryParse(roomData['temp1']?.toString() ?? '0') ?? 0;
    final temp2 = num.tryParse(roomData['temp2']?.toString() ?? '0') ?? 0;
    final tempThresholds = thresholds['temperature'] as Map<String, dynamic>? ?? 
        {'medium': 25, 'maximum': 35};
    if (temp1 > (tempThresholds['medium'] ?? 25) || 
        temp2 > (tempThresholds['medium'] ?? 25)) {
      return true;
    }
    
    final humidity1 = num.tryParse(roomData['humidity1']?.toString() ?? '0') ?? 0;
    final humidity2 = num.tryParse(roomData['humidity2']?.toString() ?? '0') ?? 0;
    final humidityThresholds = thresholds['humidity'] as Map<String, dynamic>? ?? 
        {'medium': 60, 'maximum': 80};
    if (humidity1 > (humidityThresholds['medium'] ?? 60) || 
        humidity2 > (humidityThresholds['medium'] ?? 60)) {
      return true;
    }
    
    return false;
  }
}