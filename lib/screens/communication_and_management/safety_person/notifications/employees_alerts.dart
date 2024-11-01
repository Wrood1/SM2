import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Add a complaint model to properly type the data
class Complaint {
  final String employeeId;
  final String complaint;
  final String factoryManagerId;
  final String status;
  final Timestamp timestamp;

  Complaint({
    required this.employeeId,
    required this.complaint,
    required this.factoryManagerId,
    required this.status,
    required this.timestamp,
  });

  factory Complaint.fromFirestore(Map<String, dynamic> data) {
    return Complaint(
      employeeId: data['employeeId'] as String,
      complaint: data['complaint'] as String,
      factoryManagerId: data['factoryManagerId'] as String,
      status: data['status'] as String,
      timestamp: data['timestamp'] as Timestamp,
    );
  }
}

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
  String? _factoryManagerId;
  String? _safetyPersonName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.safetyPersonId)
          .get();
      
      final userData = userDoc.data();
      if (userData != null) {
        setState(() {
          _factoryManagerId = userData['factoryManagerId'] as String?;
          _safetyPersonName = userData['name'] as String? ?? 'Safety Person';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
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

    if (_factoryManagerId == null) {
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('factoryManagerId', isEqualTo: _factoryManagerId)
          .where('status', isEqualTo: 'pending')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final complaints = snapshot.data?.docs ?? [];

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
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(complaint.employeeId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      final userName = userData?['name'] as String? ?? 'Employee';
                      return Text(
                        userName,
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
                  await FirebaseFirestore.instance
                      .collection('complaints')
                      .doc(complaintId)
                      .update({
                    'status': 'completed',
                    'response': {
                      'message': responseController.text,
                      'responderId': widget.safetyPersonId,
                      'responderName': _safetyPersonName,
                      'timestamp': FieldValue.serverTimestamp(),
                    },
                  });
                  
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