import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sensors_state_all_places.dart';
import 'configutation_navigation.dart';
import 'tools.dart';
import 'communication_and_management/factory_manager/employees_management_page.dart';
import 'communication_and_management/safety_person/commuication_alerts_safety_person_navigator.dart';
import 'communication_and_management/employee/commuication_alerts_employee_navigator.dart';
import 'notifications_page.dart';
import 'login.dart';
import '../widgets/bottom_bar.dart';  // Import the new bottom bar


class DashboardPage extends StatefulWidget {
  final String userId;
  final String userPosition;
  
  const DashboardPage({
    super.key,
    required this.userId,
    required this.userPosition,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _userName;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _showLogoutDialog(BuildContext context) {
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
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: const Text('Logout'),
            onPressed: () {
              // Perform logout logic here, e.g., using FirebaseAuth
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


  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists && mounted) {
        setState(() {
          _userName = userDoc.get('name') as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: TopHillPainter(),
              size: Size(MediaQuery.of(context).size.width, 280),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.userId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final profileImage = snapshot.data!.get('profileImage') as String?;
                                  // Update username when stream provides new data
                                  if (mounted && _userName != snapshot.data!.get('name')) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      setState(() {
                                        _userName = snapshot.data!.get('name') as String?;
                                      });
                                    });
                                  }
                                  return Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(27.5),
                                      child: profileImage != null
                                          ? Image.network(
                                              profileImage,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.brown[300],
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 35,
                                              ),
                                            ),
                                    ),
                                  );
                                }
                                return const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                                );
                              },
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome,',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  Text(
                                    _userName ?? 'Loading...',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Row(
                        children: [
                          StreamBuilder(
                            stream: FirebaseDatabase.instance.ref().onValue,
                            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                              bool hasNotifications = false;
                              if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                                final data = Map<String, dynamic>.from(
                                    snapshot.data!.snapshot.value as Map);
                                data.forEach((locationKey, locationData) {
                                  if (locationData is Map) {
                                    final locationMap = Map<String, dynamic>.from(locationData);
                                    if (locationMap['ID'] == widget.userId && locationMap['alarm'] == '1') {
                                      hasNotifications = true;
                                    }
                                  }
                                });
                              }
                              
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => NotificationsPage(userId: widget.userId),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (hasNotifications)
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 12,
                                          minHeight: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 28,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout, color: Colors.brown),
                                      SizedBox(width: 8),
                                      Text(
                                        'Logout',
                                        style: TextStyle(color: Colors.brown),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (String value) {
                                if (value == 'logout') {
                                  _showLogoutDialog(context);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'My Sections',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    children: _buildSectionButtons(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {
          // Since we only have home button, no need for additional navigation logic
        },
      ),
    );
  }

  List<Widget> _buildSectionButtons(BuildContext context) {
    final List<SectionButtonData> sections = _getSectionsForPosition();
    
    return sections.map((section) => _buildSectionButton(
      context: context,
      title: section.title,
      icon: section.icon,
      onTap: () => section.onTap(context),
    )).toList();
  }

  List<SectionButtonData> _getSectionsForPosition() {
    switch (widget.userPosition) {
      case 'Factory Manager':
        return [
          SectionButtonData(
            title: 'Employees',
            icon: Icons.people_outline,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FactoryManagementPage(factoryManagerId: widget.userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Sensors',
            icon: Icons.sensors,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CombinedSensorsPage(userId: widget.userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Config',
            icon: Icons.settings,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsNavigationPage(userId: widget.userId),
              ),
            ),
          ),
          SectionButtonData(
  title: 'Tools',
  icon: Icons.grid_4x4,
  onTap: (context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ToolsPage(
        userId: widget.userId,
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
                builder: (context) => CommunicationAlertsPageSafetyPerson(userId: widget.userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Sensors',
            icon: Icons.sensors,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CombinedSensorsPage(userId: widget.userId),
              ),
            ),
          ),
          SectionButtonData(
  title: 'Tools',
  icon: Icons.grid_4x4,
  onTap: (context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ToolsPage(
        userId: widget.userId,
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
                builder: (context) => CommunicationAlertsPageEmployee(userId: widget.userId),
              ),
            ),
          ),
          SectionButtonData(
            title: 'Sensors',
            icon: Icons.sensors,
            onTap: (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CombinedSensorsPage(userId: widget.userId),
              ),
            ),
          ),
          SectionButtonData(
  title: 'Tools',
  icon: Icons.grid_4x4,
  onTap: (context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ToolsPage(
        userId: widget.userId,
      ),
    ),
  ),
),
        ];
      default:
        return [];
    }
  }

  Widget _buildSectionButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    borderRadius: BorderRadius.circular(15),
                  ),child: Icon(
                    icon,
                    color: Colors.brown[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.brown[800],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.brown[300],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopHillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[400]!
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.8);
    
    // Create a more natural curve
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 1.0,
      size.width * 0.5,
      size.height * 0.8,
    );
    
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.6,
      size.width,
      size.height * 0.8,
    );
    
    path.lineTo(size.width, 0);
    path.close();

    // Add gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.brown[400]!,
        Colors.brown[300]!,
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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