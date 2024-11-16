// notification_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final String userId;

  NotificationService({required this.userId}) {
    _initializeNotifications();
    _startListening();
  }

  Future<void> _initializeNotifications() async {
    const androidInitialize = AndroidInitializationSettings('app_icon');
    const iosInitialize = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iosInitialize,
    );
    await _notifications.initialize(initializationSettings);
  }

  void _startListening() {
    _database.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        _checkForAlarms(data);
      }
    });
  }

  void _checkForAlarms(Map<String, dynamic> data) {
    data.forEach((locationKey, locationData) {
      if (locationData is Map) {
        final locationMap = Map<String, dynamic>.from(locationData);
        if (locationMap['ID'] == userId && locationMap['alarm'] == '1') {
          _showNotification(
            locationKey,
            locationMap['name'] ?? 'Unknown Location',
            'Critical alarm detected at ${locationMap['name']}',
          );
        }
      }
    });
  }

  Future<void> _showNotification(String locationId, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      locationId.hashCode,
      title,
      body,
      details,
    );
  }
}

