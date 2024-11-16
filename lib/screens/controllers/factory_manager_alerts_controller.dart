// broadcast_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BroadcastController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  Stream<QuerySnapshot> getBroadcastsStream(bool isCompleted, String factoryManagerId) {
    return _firestore
        .collection('broadcasts')
        .where('status', isEqualTo: isCompleted ? 'completed' : 'pending')
        .where('factoryManagerId', isEqualTo: factoryManagerId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getCompletedByUser(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  Future<void> completeBroadcast(
    String broadcastId,
    String userId,
    String response,
    BuildContext context,
  ) async {
    try {
      await _firestore.collection('broadcasts').doc(broadcastId).update({
        'status': 'completed',
        'completedBy': userId,
        'completedAt': FieldValue.serverTimestamp(),
        'response': response,
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast marked as completed')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing broadcast: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  void logError(String operation, dynamic error, StackTrace? stackTrace) {
    print('Error during $operation:');
    print('Error: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}