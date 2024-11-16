// controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/employee_alerts_model.dart';

class ComplaintsController {
  final String safetyPersonId;
  String? factoryManagerId;
  String? safetyPersonName;

  ComplaintsController({required this.safetyPersonId});

  Future<void> fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(safetyPersonId)
          .get();
      
      final userData = userDoc.data();
      if (userData != null) {
        factoryManagerId = userData['factoryManagerId'] as String?;
        safetyPersonName = userData['name'] as String? ?? 'Safety Person';
      }
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }

  Stream<List<QueryDocumentSnapshot>> getComplaintsStream() {
    return FirebaseFirestore.instance
        .collection('complaints')
        .where('factoryManagerId', isEqualTo: factoryManagerId)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  Future<String?> getEmployeeName(String employeeId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(employeeId)
        .get();
    
    if (snapshot.exists) {
      final userData = snapshot.data();
      return userData?['name'] as String? ?? 'Employee';
    }
    return null;
  }

  Future<void> submitResponse(String complaintId, String response) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .update({
        'status': 'completed',
        'response': {
          'message': response,
          'responderId': safetyPersonId,
          'responderName': safetyPersonName,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      print('Error submitting response: $e');
      rethrow;
    }
  }
}