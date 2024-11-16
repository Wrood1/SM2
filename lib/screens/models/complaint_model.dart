// complaint_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String employeeId;
  final String factoryManagerId;
  final String complaint;
  final String status;
  final Timestamp timestamp;
  final Map<String, dynamic>? response;

  ComplaintModel({
    required this.id,
    required this.employeeId,
    required this.factoryManagerId,
    required this.complaint,
    required this.status,
    required this.timestamp,
    this.response,
  });

  factory ComplaintModel.fromMap(String id, Map<String, dynamic> map) {
    return ComplaintModel(
      id: id,
      employeeId: map['employeeId'] ?? '',
      factoryManagerId: map['factoryManagerId'] ?? '',
      complaint: map['complaint'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      response: map['response'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'factoryManagerId': factoryManagerId,
      'complaint': complaint,
      'status': status,
      'timestamp': timestamp,
      'response': response,
    };
  }
}