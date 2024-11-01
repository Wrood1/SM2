import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Add this import
import '../../../widgets/bottom_bar.dart';

class CommunicationAlertsPageEmployee extends StatefulWidget {
  final String userId;

  const CommunicationAlertsPageEmployee({
    Key? key, 
    required this.userId,
  }) : super(key: key);

  @override
  _CommunicationAlertsPageEmployeeState createState() => _CommunicationAlertsPageEmployeeState();
}

class _CommunicationAlertsPageEmployeeState extends State<CommunicationAlertsPageEmployee> {
  final TextEditingController _complaintController = TextEditingController();
  String? _factoryManagerId;
  bool _isLoading = true;
  // Add this to track the current bottom bar index
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchFactoryManagerId();
  }

  Future<void> _fetchFactoryManagerId() async {
    try {
      print('Attempting to fetch factoryManagerId for user: ${widget.userId}');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      setState(() {
        _factoryManagerId = userDoc.data()?['factoryManagerId'];
        _isLoading = false;
      });
      print('Successfully fetched factoryManagerId: $_factoryManagerId');
    } catch (e, stackTrace) {
      print('ERROR: Error fetching factoryManagerId');
      print('Error details: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5E6D3),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_factoryManagerId == null) {
      print('ERROR: factoryManagerId is null for user: ${widget.userId}');
      return Scaffold(
        backgroundColor: const Color(0xFFF5E6D3),
        body: Center(
          child: Text('Error: Unable to load user data'),
        ),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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
                        SizedBox(height: 20),
                        ElevatedButton(
                          child: Text('Submit Complaint'),
                          onPressed: _submitComplaint,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: _buildComplaintsList(),
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
  Widget _buildComplaintsList() {
    print('Building complaints list for user: ${widget.userId}');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .where('employeeId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('ERROR: Error fetching complaints');
          print('Error details: ${snapshot.error}');
          if (snapshot.error is FirebaseException) {
            FirebaseException error = snapshot.error as FirebaseException;
            print('Firebase error code: ${error.code}');
            print('Firebase error message: ${error.message}');
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final complaints = snapshot.data?.docs ?? [];
        print('Successfully fetched ${complaints.length} complaints');
        return ListView.builder(
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            try {
              final complaint = complaints[index].data() as Map<String, dynamic>;
              return _buildComplaintCard(complaint, complaints[index].id);
            } catch (e, stackTrace) {
              print('ERROR: Error building complaint card at index $index');
              print('Error details: $e');
              print('Stack trace: $stackTrace');
              return Card(
                child: ListTile(
                  title: Text('Error loading complaint'),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint, String complaintId) {
    try {
      final status = complaint['status'] ?? 'pending';
      final response = complaint['response'] as Map<String, dynamic>?;

      return Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: InkWell(
          onTap: () => _showComplaintDetails(complaint, complaintId),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        complaint['complaint'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(status),
                  ],
                ),
                if (response != null) ...[
                  SizedBox(height: 8),
                  Text(
                    'Responded by: ${response['responderName'] ?? 'Safety Person'}',
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
    } catch (e, stackTrace) {
      print('ERROR: Error building complaint card');
      print('Error details: $e');
      print('Stack trace: $stackTrace');
      print('Complaint data: $complaint');
      return Card(
        child: ListTile(
          title: Text('Error displaying complaint'),
        ),
      );
    }
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  void _showComplaintDetails(Map<String, dynamic> complaint, String complaintId) {
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complaint Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(complaint['complaint'] ?? ''),
              SizedBox(height: 16),
              if (complaint['response'] != null) ...[
                Text(
                  'Response',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(complaint['response']['message'] ?? ''),
                Text(
                  'Responded by: ${complaint['response']['responderName']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              SizedBox(height: 20),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('ERROR: Error showing complaint details');
      print('Error details: $e');
      print('Stack trace: $stackTrace');
      print('Complaint data: $complaint');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error displaying complaint details')),
      );
    }
  }

  void _submitComplaint() async {
    if (_complaintController.text.isEmpty) {
      print('Warning: Attempted to submit empty complaint');
      return;
    }

    try {
      print('Attempting to submit complaint for user: ${widget.userId}');
      await FirebaseFirestore.instance.collection('complaints').add({
        'employeeId': widget.userId,
        'factoryManagerId': _factoryManagerId,
        'complaint': _complaintController.text,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Successfully submitted complaint');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Complaint submitted successfully')),
      );

      _complaintController.clear();
    } catch (e, stackTrace) {
      print('ERROR: Failed to submit complaint');
      print('Error details: $e');
      print('Stack trace: $stackTrace');
      print('Attempted to submit with userId: ${widget.userId}');
      print('FactoryManagerId: $_factoryManagerId');
      print('Complaint text: ${_complaintController.text}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit complaint. Please try again.')),
      );
    }
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.brown[700], size: 28),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.brown[300], size: 28),
            onPressed: () {},
          ),
        ],
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