// CONTROLLER: communication_alerts_controller.dart
import 'package:flutter/material.dart';
import '../models/communication_alerts_model_safety.dart';

class CommunicationAlertsController {
  final CommunicationAlertsModel model;

  CommunicationAlertsController({required this.model});

  void onBottomBarTap(int index) {
    model.currentIndex = index;
  }

  Widget buildCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.brown[700]),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
