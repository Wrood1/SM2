// view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/employee_alerts_model.dart';
import '../controllers/employee_alerts_controller.dart';

class SafetyPersonComplaintsPage extends StatefulWidget {
  final String safetyPersonId;

  const SafetyPersonComplaintsPage({
    super.key,
    required this.safetyPersonId,
  });

  @override
  _SafetyPersonComplaintsPageState createState() => _SafetyPersonComplaintsPageState();
}

class _SafetyPersonComplaintsPageState extends State<SafetyPersonComplaintsPage> {
  late ComplaintsController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = ComplaintsController(safetyPersonId: widget.safetyPersonId);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _controller.fetchUserData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5E6D3),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_controller.factoryManagerId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5E6D3),
        body: Center(
          child: Text('Error: Unable to load user data'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        title: const Text('Pending Complaints'),
        backgroundColor: Colors.brown[300],
      ),
      body: _buildComplaintsList(),
    );
  }

  Widget _buildComplaintsList() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _controller.getComplaintsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final complaints = snapshot.data ?? [];

        if (complaints.isEmpty) {
          return Center(
            child: Text(
              'No pending complaints',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaintData = complaints[index].data() as Map<String, dynamic>;
            final complaint = Complaint.fromFirestore(complaintData);
            return _buildComplaintCard(complaint, complaints[index].id);
          },
        );
      },
    );
  }

  Widget _buildComplaintCard(Complaint complaint, String complaintId) {
    final dateStr = DateFormat('MMM dd, yyyy - HH:mm').format(complaint.timestamp.toDate());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                FutureBuilder<String?>(
                  future: _controller.getEmployeeName(complaint.employeeId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.data!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      );
                    }
                    return const Text('Loading...');
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complaint.complaint,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showResponseDialog(complaintId),
              icon: const Icon(Icons.reply),
              label: const Text('Respond'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResponseDialog(String complaintId) {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Complaint'),
        content: TextField(
          controller: responseController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter your response',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.isNotEmpty) {
                try {
                  await _controller.submitResponse(
                    complaintId,
                    responseController.text,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Response submitted successfully')),
                  );
                  
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to submit response. Please try again.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown[700],
            ),
            child: const Text('Submit'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}