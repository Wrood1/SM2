// dashboard_controller.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../views/login.dart';
import '../models/dashboard_model.dart';

class DashboardController {
  final DashboardModel model;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DashboardController({
    required this.model,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance;

  Future<void> loadUserData() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(model.userId)
          .get();
      
      if (userDoc.exists) {
        model.userName = userDoc.get('name') as String?;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                FirebaseAuth.instance.signOut().then((_) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }
}