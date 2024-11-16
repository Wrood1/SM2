// model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String message;
  final String userId;
  final String senderName;
  final Timestamp timestamp;
  final String factoryManagerId;

  ChatMessage({
    required this.message,
    required this.userId,
    required this.senderName,
    required this.timestamp,
    required this.factoryManagerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'userId': userId,
      'senderName': senderName,
      'timestamp': timestamp,
      'factoryManagerId': factoryManagerId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      message: map['message'] ?? '',
      userId: map['userId'] ?? '',
      senderName: map['senderName'] ?? 'Unknown User',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      factoryManagerId: map['factoryManagerId'] ?? '',
    );
  }
}
