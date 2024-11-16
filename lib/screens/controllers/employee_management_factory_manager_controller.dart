// controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/employee_management_factory_manager_model.dart';

class FactoryManagementController {
  final String factoryManagerId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FactoryManagementController({required this.factoryManagerId});

  Future<List<Person>> loadPersonsByPosition(String position) async {
    final QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('position', isEqualTo: position)
        .where('factoryManagerId', isEqualTo: factoryManagerId)
        .get();

    return querySnapshot.docs
        .map((doc) => Person.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> addPerson(String email, String position, BuildContext context) async {
    final QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    final userDoc = querySnapshot.docs.first;
    final userData = userDoc.data() as Map<String, dynamic>;

    if (userData['factoryManagerId'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This user is already assigned to another factory manager')),
      );
      return;
    }

    await userDoc.reference.update({
      'factoryManagerId': factoryManagerId,
      'position': position,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$position added successfully')),
    );
  }

  Future<void> deletePerson(String userId, BuildContext context) async {
    await _firestore.collection('users').doc(userId).update({
      'factoryManagerId': null,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Person removed successfully')),
    );
  }
}