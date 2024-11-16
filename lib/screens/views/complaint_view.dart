// complaint_view.dart

import 'package:flutter/material.dart';
import '../../../widgets/bottom_bar.dart';
import '../controllers/complaint_controller.dart';
import '../models/complaint_model.dart';

class CommunicationAlertsPageEmployee extends StatefulWidget {
  final String userId;

  const CommunicationAlertsPageEmployee({
    super.key, 
    required this.userId,
  });

  @override
  _CommunicationAlertsPageEmployeeState createState() => _CommunicationAlertsPageEmployeeState();
}

class _CommunicationAlertsPageEmployeeState extends State<CommunicationAlertsPageEmployee> {
  final TextEditingController _complaintController = TextEditingController();
  final ComplaintController _controller = ComplaintController();
  String? _factoryManagerId;
  bool _isLoading = true;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchFactoryManagerId();
  }

  Future<void> _fetchFactoryManagerId() async {
    final managerId = await _controller.fetchFactoryManagerId(widget.userId);
    setState(() {
      _factoryManagerId = managerId;
      _isLoading = false;
    });
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _showComplaintDetails(complaint),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      complaint.complaint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(complaint.status),
                ],
              ),
              if (complaint.response != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Responded by: ${complaint.response?['responderName'] ?? 'Safety Person'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showComplaintDetails(ComplaintModel complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complaint Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(complaint.complaint),
            const SizedBox(height: 16),
            if (complaint.response != null) ...[
              const Text(
                'Response',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(complaint.response?['message'] ?? ''),
              Text(
                'Responded by: ${complaint.response?['responderName']}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _submitComplaint() async {
    if (_complaintController.text.isEmpty || _factoryManagerId == null) return;

    final success = await _controller.submitComplaint(
      employeeId: widget.userId,
      factoryManagerId: _factoryManagerId!,
      complaintText: _complaintController.text,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully')),
      );
      _complaintController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit complaint. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5E6D3),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_factoryManagerId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5E6D3),
        body: Center(child: Text('Error: Unable to load user data')),
      );
    }

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
                    'Report a Complaint',
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
                        TextField(
                          controller: _complaintController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Describe your complaint here',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitComplaint,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: Text('Submit Complaint'),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: StreamBuilder<List<ComplaintModel>>(
                            stream: _controller.getComplaints(widget.userId),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(child: Text('Error: ${snapshot.error}'));
                              }

                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final complaints = snapshot.data ?? [];
                              return ListView.builder(
                                itemCount: complaints.length,
                                itemBuilder: (context, index) => _buildComplaintCard(complaints[index]),
                              );
                            },
                          ),
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
        onTap: (index) {
          setState(() {
            _currentIndex = index;
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