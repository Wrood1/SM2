import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatPage extends StatefulWidget {
  final String userId;

  const GroupChatPage({super.key, required this.userId});

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _factoryManagerId;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _factoryManagerId = userData['factoryManagerId']?.toString() ?? '';
          _userName = userData['name']?.toString() ?? 'Unknown User';
          _isLoading = false;
        });
        print('User Data Loaded - Name: $_userName, FactoryManagerId: $_factoryManagerId'); // Debug log
      } else {
        print('User document does not exist');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Colors.blue,
            onPressed: () => _sendMessage(),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    // Debug prints to track execution
    print('Send message attempt');
    print('Message text: ${_messageController.text}');
    print('Factory Manager ID: $_factoryManagerId');
    print('User Name: $_userName');
    
    if (_messageController.text.trim().isEmpty) {
      print('Message is empty');
      return;
    }

    if (_factoryManagerId == null || _factoryManagerId!.isEmpty) {
      print('Factory Manager ID is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send message. User data not loaded.')),
      );
      return;
    }

    try {
      // Create message data
      final messageData = {
        'message': _messageController.text.trim(),
        'userId': widget.userId,
        'senderName': _userName,
        'timestamp': FieldValue.serverTimestamp(),
        'factoryManagerId': _factoryManagerId,
      };

      print('Attempting to send message: $messageData'); // Debug log

      // Send to Firestore
      await FirebaseFirestore.instance
          .collection('group_chat')
          .add(messageData);

      print('Message sent successfully'); // Debug log

      // Clear the input field
      setState(() {
        _messageController.clear();
      });

      // Scroll to bottom
      _scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      print('Error sending message: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
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
              size: Size(MediaQuery.of(context).size.width, 250),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text(
                    'Factory Group Chat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('group_chat')
      .where('factoryManagerId', isEqualTo: _factoryManagerId)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      // Detailed error logging
      print('========== FIRESTORE ERROR ==========');
      print('Error Code: ${(snapshot.error as FirebaseException).code}');
      print('Error Message: ${(snapshot.error as FirebaseException).message}');
      print('Error Details: ${snapshot.error.toString()}');
      
      // If it's an index error, it will contain the URL in the message
      if ((snapshot.error as FirebaseException).code == 'failed-precondition' ||
          (snapshot.error as FirebaseException).code == 'failed-production') {
        final errorMessage = (snapshot.error as FirebaseException).message ?? '';
        final urlMatch = RegExp(r'https:\/\/console\.firebase\.google\.com[^\s]+').firstMatch(errorMessage);
        if (urlMatch != null) {
          print('\n========== INDEX URL ==========');
          print('Create your composite index at:');
          print(urlMatch.group(0));
          print('================================\n');
        }
      }
      
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

                            List<DocumentSnapshot> docs = snapshot.data!.docs;

                            if (docs.isEmpty) {
                              return Center(
                                child: Text(
                                  'No messages yet.\nBe the first to send a message!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              reverse: true,
                              controller: _scrollController,
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> data = 
                                    docs[index].data() as Map<String, dynamic>;
                                bool isMe = data['userId'] == widget.userId;

                                return _buildMessageBubble(
                                  message: data['message'] ?? '',
                                  isMe: isMe,
                                  sender: data['senderName'] ?? 'Unknown User',
                                  timestamp: data['timestamp'] ?? Timestamp.now(),
                                );
                              },
                            );
                          },
                        ),
                ),
                _buildMessageComposer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required String sender,
    required Timestamp timestamp,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.brown[300] : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
          Text(
            _formatTimestamp(timestamp),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
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