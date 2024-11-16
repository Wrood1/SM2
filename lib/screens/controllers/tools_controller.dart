import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/tool_model.dart';

// controllers/tools_controller.dart
class ToolsController {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? factoryManagerId;
  Map<String, dynamic>? userLocation;
  String? userPosition;
  bool canAddTools = false;
  Map<String, Map<String, String>> locationRooms = {};

  ToolsController({required this.userId});

  Future<void> initialize() async {
    await fetchUserRole();
    await fetchLocationData();
    await fetchRoomData();
  }

  Future<void> fetchUserRole() async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        factoryManagerId = userData?['factoryManagerId'] as String?;
        userPosition = userData?['position'] as String?;
        canAddTools = userPosition == 'Safety Person' || userPosition == 'Factory Manager';
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  Future<bool> shouldShowTool(Map<String, dynamic> toolData) async {
    final toolUserId = toolData['userId'] as String?;
    
    if (toolUserId == null) return false;
    if (toolUserId == userId) return true;

    try {
      final toolCreatorDoc = await _firestore
          .collection('users')
          .doc(toolUserId)
          .get();

      if (!toolCreatorDoc.exists) return false;

      final toolCreatorData = toolCreatorDoc.data()!;
      final toolCreatorFactoryManagerId = toolCreatorData['factoryManagerId'] as String?;

      switch (userPosition) {
        case 'Factory Manager':
          return userId == toolCreatorFactoryManagerId;
        case 'Safety Person':
          if (factoryManagerId == toolCreatorFactoryManagerId) return true;
          if (toolUserId == factoryManagerId) return true;
          return false;
        case 'Employee':
          if (toolUserId == factoryManagerId) return true;
          return factoryManagerId == toolCreatorFactoryManagerId;
        default:
          return false;
      }
    } catch (e) {
      print('Error checking tool visibility: $e');
      return false;
    }
  }

  bool hasAccessToLocation(Map<String, dynamic> locationData) {
    if (userId == locationData['ID']) return true;
    if (factoryManagerId != null && locationData['ID'] == factoryManagerId) return true;
    return false;
  }

  Future<void> fetchLocationData() async {
    try {
      final url = Uri.parse('https://smart-64616-default-rtdb.firebaseio.com/.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        for (var entry in data.entries) {
          if (entry.value is Map<String, dynamic>) {
            final locationData = entry.value as Map<String, dynamic>;
            
            if (hasAccessToLocation(locationData)) {
              userLocation = {
                ...locationData,
                'key': entry.key,
              };
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching location data: $e');
    }
  }

  Future<void> fetchRoomData() async {
    if (userLocation == null) return;

    try {
      Map<String, Map<String, String>> rooms = {};
      final location = userLocation!['name'] as String;
      rooms[location] = {};

      userLocation!.forEach((key, value) {
        if (key.startsWith('room') && value is Map) {
          final roomId = key;
          final roomName = value['name'] as String? ?? key;
          rooms[location]![roomId] = roomName;
        }
      });

      locationRooms = rooms;
    } catch (e) {
      print('Error processing rooms: $e');
    }
  }

  Future<void> addTool({
    required String name,
    required String location,
    required String roomId,
    required DateTime maintenanceDate,
    required DateTime expirationDate,
  }) async {
    await _firestore.collection('tools').add({
      'name': name,
      'location': location,
      'roomId': roomId,
      'roomName': locationRooms[location]?[roomId],
      'maintenanceDate': maintenanceDate,
      'expirationDate': expirationDate,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': userId,
    });
  }

  Stream<List<Tool>> getToolsStream(String searchTerm) {
    return _firestore
        .collection('tools')
        .snapshots()
        .asyncMap((snapshot) async {
          final filteredDocs = snapshot.docs.where((doc) {
            final data = doc.data();
            return data['name'].toString().toLowerCase().contains(searchTerm.toLowerCase());
          }).toList();

          final visibleTools = await Future.wait(
            filteredDocs.map((doc) async {
              if (await shouldShowTool(doc.data())) {
                return Tool.fromMap(doc.data());
              }
              return null;
            }),
          );

          return visibleTools.where((tool) => tool != null).cast<Tool>().toList();
        });
  }
}