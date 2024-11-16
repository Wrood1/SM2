// complaint_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';

class ComplaintController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<String?> fetchFactoryManagerId(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['factoryManagerId'];
    } catch (e) {
      print('Error fetching factoryManagerId: $e');
      return null;
    }
  }

  Stream<List<ComplaintModel>> getComplaints(String employeeId) {
    return _firestore
        .collection('complaints')
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ComplaintModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<bool> submitComplaint({
    required String employeeId,
    required String factoryManagerId,
    required String complaintText,
  }) async {
    try {
      await _firestore.collection('complaints').add({
        'employeeId': employeeId,
        'factoryManagerId': factoryManagerId,
        'complaint': complaintText,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error submitting complaint: $e');
      return false;
    }
  }
}