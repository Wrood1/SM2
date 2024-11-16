// broadcast_history_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BroadcastHistoryController {
  final String factoryManagerId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BroadcastHistoryController({required this.factoryManagerId});

  Stream<QuerySnapshot> getBroadcastsStream() {
    return _firestore
        .collection('broadcasts')
        .where('factoryManagerId', isEqualTo: factoryManagerId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> sendBroadcastMessage(String message, BuildContext context) async {
    try {
      // Create broadcast document
      DocumentReference broadcastRef = await _firestore.collection('broadcasts').add({
        'message': message,
        'factoryManagerId': factoryManagerId,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'completedBy': null,
        'completedAt': null,
        'response': null,
      });

      // Get safety persons
      QuerySnapshot safetyPersons = await _firestore
          .collection('users')
          .where('position', isEqualTo: 'Safety Person')
          .where('factoryManagerId', isEqualTo: factoryManagerId)
          .get();

      // Create notifications batch
      WriteBatch batch = _firestore.batch();
      for (var doc in safetyPersons.docs) {
        DocumentReference notificationRef = _firestore
            .collection('users')
            .doc(doc.id)
            .collection('notifications')
            .doc(broadcastRef.id);

        batch.set(notificationRef, {
          'type': 'broadcast',
          'broadcastId': broadcastRef.id,
          'message': message,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }

      await batch.commit();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast message sent successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending broadcast: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> getCompletedByUserDetails(String userId) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>?;
  }

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}