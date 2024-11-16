import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartsavior2/utils/colors.dart';
import '../../widgets/bottom_bar.dart';
import '../models/dashboard_model.dart';
import '../controllers/dashboard_controller.dart';
import 'notifications_page.dart';

class DashboardView extends StatefulWidget {
  final String userId;
  final String userPosition;

  const DashboardView({
    super.key,
    required this.userId,
    required this.userPosition,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late final DashboardModel _model;
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _model = DashboardModel(
      userId: widget.userId,
      userPosition: widget.userPosition,
    );
    _controller = DashboardController(model: _model);
    _controller.loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().backgroundColor,
      body: Stack(
        children: [
          // Background Curve Painter
          CustomPaint(
            painter: TopHillPainter(),
            child: Container(height: 300),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 80),
                _buildSectionTitle(),
                const SizedBox(height: 20),
                _buildSectionsGrid(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildUserProfile()),
              Row(
                children: [
                  const SizedBox(width: 8),
                  _buildMoreOptionsButton(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),

          const Text(
            "My Dashboard",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),

          // "Your safety in smart hands" slogan
          Text(
            "Your safety in smart hands",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),

          // Profile and options

        ],
      ),
    );
  }


  Widget _buildUserProfile() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final profileImage = userData['profileImage'] as String?;
          final userName = userData['name'] as String? ?? 'User';

          if (mounted && userName != _model.userName) {
            _model.userName = userName;
          }

          return Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27.5),
                  child: profileImage != null
                      ? Image.network(profileImage, fit: BoxFit.cover)
                      : Container(
                    color: AppColors().primaryColor,
                    child: const Icon(Icons.person, color: Colors.white, size: 35),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome,',
                      style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          'My Sections',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors().primaryColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionsGrid() {
    return Expanded(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: _model.getSectionsForPosition().map((section) => _buildSectionButton(
            title: section.title,
            icon: section.icon,
            onTap: () => section.onTap(context),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionButton({required String title, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.40,
      height: 175,
      child: Material(
        elevation: 5,
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors().primaryColor, size: 45),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors().primaryColor, fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Additional content below sections grid



  Widget _buildMoreOptionsButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors().primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String>(
        color: Colors.white,
        icon:  Icon(
          Icons.logout,
          color: AppColors().secondaryColor,
          size: 28,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'logout',
            child: Container(
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppColors().primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(color: AppColors().primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
        onSelected: (String value) {
          if (value == 'logout') {
            _controller.showLogoutDialog(context);
          }
        },
      ),
    );
  }
}

class TopHillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors().primaryColor..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.25, size.height * 1.0, size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.6, size.width, size.height * 0.8);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashboardPage extends StatelessWidget {
  final String userId;
  final String userPosition;

  const DashboardPage({
    super.key,
    required this.userId,
    required this.userPosition,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardView(userId: userId, userPosition: userPosition);
  }
}