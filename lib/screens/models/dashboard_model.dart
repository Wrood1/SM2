// dashboard_model.dart

import 'package:flutter/material.dart';
import '../views/configutation_navigation.dart';
import '../views/employee_management_factory_manager_view.dart';
import '../views/sensors_state_all_places.dart';
import '../views/tools_view.dart';
import '../views/communication_alerts_view_safety.dart';
import '../views/complaint_view.dart';

class DashboardModel {
  final String userId;
  final String userPosition;
  String? userName;

  DashboardModel({
    required this.userId,
    required this.userPosition,
    this.userName,
  });

  List<SectionButtonData> getSectionsForPosition() {
    switch (userPosition) {
      case 'Factory Manager':
        return [
          SectionButtonData(
            title: 'Employees',
            icon: Icons.people_outline,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FactoryManagementPage(factoryManagerId: userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Sensors',
            icon: Icons.sensors,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CombinedSensorsPage(userId: userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Config',
            icon: Icons.settings,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsNavigationPage(userId: userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Tools',
            icon: Icons.widgets_outlined,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ToolsView(
                  userId: userId,
                ),
              ),
            ),
          ),
        ];
      case 'Safety Person':
        return [
          SectionButtonData(
            title: 'Communication and Alerts',
            icon: Icons.notifications_active,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunicationAlertsPageSafetyPerson(userId: userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Sensors',
            icon: Icons.sensors,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CombinedSensorsPage(userId: userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Tools',
            icon: Icons.grid_4x4,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ToolsView(
                  userId: userId,
                ),
              ),
            ),
          ),
        ];
      case 'Employee':
        return [
          SectionButtonData(
            title: 'Communication and Alerts',
            icon: Icons.notifications_active,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommunicationAlertsPageEmployee(userId: userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Sensors',
            icon: Icons.sensors,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CombinedSensorsPage(userId: userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Tools',
            icon: Icons.grid_4x4,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ToolsView(
                  userId: userId,
                ),
              ),
            ),
          ),
        ];
      default:
        return [];
    }
  }
}

class SectionButtonData {
  final String title;
  final IconData icon;
  final Function(BuildContext) onTap;

  SectionButtonData({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}