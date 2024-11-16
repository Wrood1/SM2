// broadcast_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Broadcast {
  final String id;
  final String message;
  final String status;
  final String factoryManagerId;
  final String? completedBy;
  final DateTime? completedAt;
  final String? response;
  final DateTime timestamp;

  Broadcast({
    required this.id,
    required this.message,
    required this.status,
    required this.factoryManagerId,
    this.completedBy,
    this.completedAt,
    this.response,
    required this.timestamp,
  });

  factory Broadcast.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Broadcast(
      id: doc.id,
      message: data['message'] ?? 'No message available',
      status: data['status'] ?? 'unknown',
      factoryManagerId: data['factoryManagerId'] ?? '',
      completedBy: data['completedBy'],
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      response: data['response'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'status': status,
      'factoryManagerId': factoryManagerId,
      'completedBy': completedBy,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'response': response,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}