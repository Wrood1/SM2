// notification_model.dart

class NotificationModel {
  final String type;
  final String title;
  final String message;
  final String timestamp;
  final int level;

  NotificationModel({
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.level,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? '',
      level: map['level'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'level': level,
    };
  }
}

class RoomModel {
  final String name;
  final String level;

  RoomModel({
    required this.name,
    required this.level,
  });

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      name: map['name'] ?? '',
      level: map['level']?.toString() ?? '0',
    );
  }
}

class LocationModel {
  final String id;
  final String name;
  final Map<String, dynamic> configuration;
  final Map<String, dynamic> rooms;
  final String key;

  LocationModel({
    required this.id,
    required this.name,
    required this.configuration,
    required this.rooms,
    required this.key,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map, String locationKey) {
    // Convert ID to string if it's an integer
    String id = map['ID']?.toString() ?? '';
    
    // Filter rooms from the map
    Map<String, dynamic> roomsMap = {};
    map.forEach((key, value) {
      if (key.startsWith('room') && value is Map) {
        roomsMap[key] = value;
      }
    });

    return LocationModel(
      id: id,
      name: map['name']?.toString() ?? '',
      configuration: Map<String, dynamic>.from(map['configuration'] ?? {}),
      rooms: roomsMap,
      key: locationKey,
    );
  }
}
