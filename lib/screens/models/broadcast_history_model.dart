// broadcast_history_model.dart
class BroadcastModel {
  final String message;
  final String factoryManagerId;
  final DateTime? timestamp;
  final String status;
  final String? completedBy;
  final DateTime? completedAt;
  final String? response;

  BroadcastModel({
    required this.message,
    required this.factoryManagerId,
    this.timestamp,
    this.status = 'pending',
    this.completedBy,
    this.completedAt,
    this.response,
  });

  factory BroadcastModel.fromMap(Map<String, dynamic> map) {
    return BroadcastModel(
      message: map['message'] ?? '',
      factoryManagerId: map['factoryManagerId'] ?? '',
      timestamp: map['timestamp']?.toDate(),
      status: map['status'] ?? 'pending',
      completedBy: map['completedBy'],
      completedAt: map['completedAt']?.toDate(),
      response: map['response'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'factoryManagerId': factoryManagerId,
      'timestamp': timestamp,
      'status': status,
      'completedBy': completedBy,
      'completedAt': completedAt,
      'response': response,
    };
  }
}