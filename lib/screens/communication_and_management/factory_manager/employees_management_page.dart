import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/bottom_bar.dart';

class FactoryManagementPage extends StatefulWidget {
  final String factoryManagerId;

  const FactoryManagementPage({super.key, required this.factoryManagerId});

  @override
  _FactoryManagementPageState createState() => _FactoryManagementPageState();
}

class _FactoryManagementPageState extends State<FactoryManagementPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _safetyPersons = [];
  List<Map<String, dynamic>> _employees = [];
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSafetyPersons();
    _loadEmployees();

    // Add listener for tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _loadSafetyPersons() {
    FirebaseFirestore.instance
        .collection('users')
        .where('position', isEqualTo: 'Safety Person')
        .where('factoryManagerId', isEqualTo: widget.factoryManagerId)
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        _safetyPersons = querySnapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                })
            .toList();
      });
    });
  }

  void _loadEmployees() {
    FirebaseFirestore.instance
        .collection('users')
        .where('position', isEqualTo: 'Employee')
        .where('factoryManagerId', isEqualTo: widget.factoryManagerId)
        .get()
        .then((QuerySnapshot querySnapshot) {
      setState(() {
        _employees = querySnapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                })
            .toList();
      });
    });
  }

  void _showAddPersonDialog(BuildContext context, String position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add $position'),
          content: TextField(
            controller: _emailController,
            decoration:
                InputDecoration(hintText: "Enter ${position.toLowerCase()}'s email"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (_emailController.text.isNotEmpty) {
                  _addPerson(_emailController.text, position);
                  _emailController.clear();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addPerson(String email, String position) async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    final userDoc = querySnapshot.docs.first;
    final userData = userDoc.data() as Map<String, dynamic>;

    if (userData['factoryManagerId'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('This user is already assigned to another factory manager')),
      );
      return;
    }

    await userDoc.reference.update({
      'factoryManagerId': widget.factoryManagerId,
      'position': position,
    });

    setState(() {
      if (position == 'Safety Person') {
        _safetyPersons.add({
          ...userData,
          'id': userDoc.id,
          'factoryManagerId': widget.factoryManagerId
        });
      } else {
        _employees.add({
          ...userData,
          'id': userDoc.id,
          'factoryManagerId': widget.factoryManagerId
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$position added successfully')),
    );
  }

  void _showBroadcastDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Broadcast Message'),
          content: TextField(
            controller: _messageController,
            decoration: const InputDecoration(hintText: "Enter your message"),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Send'),
              onPressed: () {
                if (_messageController.text.isNotEmpty) {
                  _sendBroadcastMessage(_messageController.text);
                  _messageController.clear();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _sendBroadcastMessage(String message) async {
    DocumentReference broadcastRef =
        await FirebaseFirestore.instance.collection('broadcasts').add({
      'message': message,
      'factoryManagerId': widget.factoryManagerId,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'completedBy': null,
      'completedAt': null,
      'response': null,
    });

    QuerySnapshot safetyPersons = await FirebaseFirestore.instance
        .collection('users')
        .where('position', isEqualTo: 'Safety Person')
        .where('factoryManagerId', isEqualTo: widget.factoryManagerId)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var doc in safetyPersons.docs) {
      DocumentReference notificationRef = FirebaseFirestore.instance
          .collection('users')
          .doc(doc.id)
          .collection('notifications')
          .doc(broadcastRef.id);

      batch.set(notificationRef, {
        'type': 'broadcast',
        'broadcastId': broadcastRef.id,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Broadcast message sent successfully')),
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> person, String position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              Text('Are you sure you want to remove ${person['name']} as a $position?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deletePerson(person['id'], position);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deletePerson(String userId, String position) {
    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'factoryManagerId': null,
    }).then((_) {
      setState(() {
        if (position == 'Safety Person') {
          _safetyPersons.removeWhere((person) => person['id'] == userId);
        } else {
          _employees.removeWhere((person) => person['id'] == userId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$position removed successfully')),
      );
    });
  }

  Widget _buildUserList(bool isSafetyPerson) {
    final List<Map<String, dynamic>> users =
        isSafetyPerson ? _safetyPersons : _employees;
    final String position = isSafetyPerson ? 'Safety Person' : 'Employee';

    return Stack(
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
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search $position',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  // Implement search functionality
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final person = users[index];

                  return Dismissible(
                    key: Key(person['id']),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      _deletePerson(person['id'], position);
                    },
                    child: ListTile(
                      title: Text(person['name'] ?? 'No name'),
                      subtitle: Text(person['email'] ?? 'No email'),
                      leading: CircleAvatar(
                        backgroundImage: person['profileImage'] != null
                            ? NetworkImage(person['profileImage'])
                            : null,
                        child: person['profileImage'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _showDeleteConfirmationDialog(person, position),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBroadcastHistory() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('broadcasts')
          .where('factoryManagerId', isEqualTo: widget.factoryManagerId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No broadcasts found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var broadcast = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var timestamp = broadcast['timestamp'] as Timestamp?;
            String formattedDate = timestamp != null
                ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
                : 'No date';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      broadcast['message'] ?? 'No message',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(broadcast['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            broadcast['status']?.toUpperCase() ?? 'UNKNOWN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (broadcast['completedBy'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Completed by: ${broadcast['completedBy']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (broadcast['completedAt'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Completed at: ${(broadcast['completedAt'] as Timestamp).toDate().toString()}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

    

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      appBar: AppBar(
        backgroundColor: Colors.brown[300],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Safety Persons'),
            Tab(text: 'Employees'),
            Tab(text: 'Broadcast History'),
          ],
          indicatorColor: Colors.white,
        ),
        title: const Text(
          'Factory Management',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildUserList(true),  // Safety Persons
              _buildUserList(false), // Employees
              _buildBroadcastHistory(),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 36,
            child: FloatingActionButton(
              backgroundColor: Colors.brown[300],
              child: const Icon(Icons.add),
              onPressed: () {
                if (_tabController.index == 0) {
                  _showAddPersonDialog(context, 'Safety Person');
                } else if (_tabController.index == 1) {
                  _showAddPersonDialog(context, 'Employee');
                } else {
                  _showBroadcastDialog();
                }
              },
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