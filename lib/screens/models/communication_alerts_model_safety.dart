// MODEL: communication_alerts_model.dart
class CommunicationAlertsModel {
  final String userId;
  int currentIndex;

  CommunicationAlertsModel({
    required this.userId,
    this.currentIndex = 0,
  });
}