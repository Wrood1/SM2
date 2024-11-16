// VIEW: communication_alerts_view.dart
import 'package:flutter/material.dart';
import '../views/chat_group_view.dart';
import '../views/factory_manager_alerts_view.dart';
import '../views/employee_alerts_view.dart';
import '../../../widgets/bottom_bar.dart';
import '../models/communication_alerts_model_safety.dart';
import '../controllers/communication_alerts_controller_safety.dart';

class CommunicationAlertsPageSafetyPerson extends StatefulWidget {
  final String userId;

  const CommunicationAlertsPageSafetyPerson({super.key, required this.userId});

  @override
  State<CommunicationAlertsPageSafetyPerson> createState() => _CommunicationAlertsPageSafetyPersonState();
}

class _CommunicationAlertsPageSafetyPersonState extends State<CommunicationAlertsPageSafetyPerson> {
  late CommunicationAlertsModel _model;
  late CommunicationAlertsController _controller;

  @override
  void initState() {
    super.initState();
    _model = CommunicationAlertsModel(userId: widget.userId);
    _controller = CommunicationAlertsController(model: _model);
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                        _controller.buildCard(
                          context,
                          'Group Chat',
                          Icons.chat,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => GroupChatPage(userId: _model.userId))),
                        ),
                        const SizedBox(height: 20),
                        _controller.buildCard(
                          context,
                          'Factory Manager Alerts',
                          Icons.notifications_active,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyPersonBroadcastsPage(userId: _model.userId))),
                        ),
                        const SizedBox(height: 20),
                        _controller.buildCard(
                          context,
                          'Employee Complaints',
                          Icons.report_problem,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyPersonComplaintsPage(safetyPersonId: _model.userId))),
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
        currentIndex: _model.currentIndex,
        onTap: (index) {
          setState(() {
            _controller.onBottomBarTap(index);
          });
        },
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