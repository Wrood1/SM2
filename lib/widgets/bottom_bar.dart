import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartsavior2/utils/colors.dart';
import '../screens/views/dashboard_view.dart';
// Import all the pages

import '../screens/views/complaint_view.dart';
import '../screens/views/chat_group_view.dart';

// import '../screens/communication_and_management/safety_person/chat_group.dart';
import '../screens/views/broadcast_history_view.dart';

import '../screens/views/notifications_page.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

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

  void _navigateToPage(BuildContext context, int index, String userId, String position) {
    Widget? destinationPage;

    switch (position.toLowerCase()) {
      case 'factory manager':
        switch (index) {
          case 0:
            destinationPage = DashboardView(userId: userId, userPosition: position);
            break;
          case 1:
            destinationPage = NotificationsPage(userId: userId);
            break;
          case 2:
            destinationPage = BroadcastHistoryPage(factoryManagerId: userId);
            break;
          case 3:
            // destinationPage = ToolsPage(userId: userId);
            // break;
        }
        break;

      case 'employee':
        switch (index) {
          case 0:
            destinationPage = DashboardPage(userId: userId, userPosition: position);
            break;
          case 1:
            destinationPage = NotificationsPage(userId: userId);
            break;
          case 2:
            destinationPage = CommunicationAlertsPageEmployee(userId: userId);
            break;

        }
        break;

      case 'safety person':
        switch (index) {
          case 0:
            destinationPage = DashboardPage(userId: userId, userPosition: position);
            break;
          case 1:
            destinationPage = NotificationsPage(userId: userId);
            break;
          case 2:
            destinationPage = GroupChatPage(userId: userId);
            break;

        }
        break;
    }

    if (destinationPage != null && context.mounted) {
      if (index == 0) {
        // For home page, remove all routes and push home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => destinationPage!),
          (route) => false,
        );
      } else {
        // For other pages, keep home page in stack and push new page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => destinationPage!),
          (route) => route.isFirst, // Keep only the first route (home) in the stack
        );
      }
    }
  }

  List<Map<String, dynamic>> _getNavigationItems(String position) {
    // Common items for all users
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.home,
        'label': 'Home',
        'index': 0,
      },
      {
        'icon': Icons.notifications,
        'label': 'Notifications',
        'index': 1,
      }
    ];

    // Position-specific items
    switch (position.toLowerCase()) {
      case 'factory manager':
        items.addAll([
          {
            'icon': Icons.campaign, // Broadcast icon
            'label': 'Broadcast',
            'index': 2,
          },
          // {
          //   'icon': Icons.settings,
          //   'label': 'Settings',
          //   'index': 3,
          // },
        ]);
        break;

      case 'employee':
        items.addAll([
          {
            'icon': Icons.report_problem, // Complaint icon
            'label': 'Complaints',
            'index': 2,
          },

        ]);
        break;

      case 'safety person':
        items.addAll([
          {
            'icon': Icons.chat, // Chat icon
            'label': 'Chat',
            'index': 2,
          },

        ]);
        break;
    }

    return items;
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 80,
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            height: 80,
            color: Colors.white,
          );
        }

        final navigationItems = _getNavigationItems(snapshot.data!['userPosition']!);

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
                color: AppColors().primaryColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: navigationItems.map((item) => Container(
              decoration: BoxDecoration(
                color: currentIndex == item['index']
                    ? AppColors().primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                icon: Icon(
                  item['icon'] as IconData,
                  color: currentIndex == item['index']
                      ? AppColors().secondaryColor
                      : AppColors().primaryColor,
                  size: 28,
                ),
                onPressed: () {
                  onTap(item['index']);
                  _navigateToPage(
                    context,
                    item['index'],
                    snapshot.data!['userId']!,
                    snapshot.data!['userPosition']!
                  );
                },
              ),
            )).toList(),
          ),
        );
      },
    );
  }
}