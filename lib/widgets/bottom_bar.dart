import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/dashboard.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const CustomBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  Future<Map<String, String>> _getUserData() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      return {
        'userName': userDoc.get('name') as String,
        'userId': currentUser.uid,
        'userPosition': userDoc.get('position') as String,
      };
    }
    throw Exception('No user logged in');
  }

  Future<void> _navigateToDashboard(BuildContext context) async {
    try {
      final userData = await _getUserData();
      
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(
              userId: userData['userId']!,
              userPosition: userData['userPosition']!,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to dashboard: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: currentIndex == 0 ? Colors.brown[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              icon: Icon(
                Icons.home,
                color: currentIndex == 0 ? Colors.brown[700] : Colors.brown[300],
                size: 28,
              ),
              onPressed: () {
                onTap(0);
                _navigateToDashboard(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}