import 'package:flutter/material.dart';
import 'chat_group.dart';
import 'notifications/factory_managaer_alerts.dart';
import 'notifications/employees_alerts.dart';
import '../../../widgets/bottom_bar.dart'; // Add this import

class CommunicationAlertsPageSafetyPerson extends StatefulWidget {  // Changed to StatefulWidget
  final String userId;

  const CommunicationAlertsPageSafetyPerson({Key? key, required this.userId}) : super(key: key);

  @override
  State<CommunicationAlertsPageSafetyPerson> createState() => _CommunicationAlertsPageSafetyPersonState();
}

class _CommunicationAlertsPageSafetyPersonState extends State<CommunicationAlertsPageSafetyPerson> {
  int _currentIndex = 0;  // Add state for bottom bar

  void _onBottomBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
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
              size: Size(MediaQuery.of(context).size.width, 250),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'Communication & Alerts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildCard(
                          context,
                          'Group Chat',
                          Icons.chat,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => GroupChatPage(userId: widget.userId,))),
                        ),
                        SizedBox(height: 20),
                        _buildCard(
                          context,
                          'Factory Manager Alerts',
                          Icons.notifications_active,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyPersonBroadcastsPage(userId: widget.userId,))),
                        ),
                        SizedBox(height: 20),
                        _buildCard(
                          context,
                          'Employee Complaints',
                          Icons.report_problem,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyPersonComplaintsPage(safetyPersonId: widget.userId))),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: _onBottomBarTap,
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
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
              SizedBox(width: 20),
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
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
      ..color = Colors.brown[300]!
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 1.2,
      size.width,
      size.height * 0.7,
    );
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}