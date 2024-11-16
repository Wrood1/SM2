// model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String employeeId;
  final String complaint;
  final String factoryManagerId;
  final String status;
  final Timestamp timestamp;

  Complaint({
    required this.employeeId,
    required this.complaint,
    required this.factoryManagerId,
    required this.status,
    required this.timestamp,
  });

  factory Complaint.fromFirestore(Map<String, dynamic> data) {
    return Complaint(
      employeeId: data['employeeId'] as String,
      complaint: data['complaint'] as String,
      factoryManagerId: data['factoryManagerId'] as String,
      status: data['status'] as String,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'complaint': complaint,
      'factoryManagerId': factoryManagerId,
      'status': status,
      'timestamp': timestamp,
    };
  }
}