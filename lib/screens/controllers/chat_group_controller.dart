

// controller.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
;
import '../models/chat_group_model.dart';
class GroupChatController {
  final String userId;
  String? _factoryManagerId;
  String? _userName;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  GroupChatController({required this.userId});

  String? get factoryManagerId => _factoryManagerId;
  String? get userName => _userName;

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _factoryManagerId = userData['factoryManagerId']?.toString() ?? '';
        _userName = userData['name']?.toString() ?? 'Unknown User';
        print('User Data Loaded - Name: $_userName, FactoryManagerId: $_factoryManagerId');
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getChatStream() {
    return FirebaseFirestore.instance
        .collection('group_chat')
        .where('factoryManagerId', isEqualTo: _factoryManagerId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> sendMessage(BuildContext context) async {
    print('Send message attempt');
    final messageText = messageController.text.trim();
    print('Message text: $messageText');
    
    if (messageText.isEmpty) {
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
      final chatMessage = ChatMessage(
        message: messageText,
        userId: userId,
        senderName: _userName ?? 'Unknown User',
        timestamp: Timestamp.now(),
        factoryManagerId: _factoryManagerId!,
      );

      print('Attempting to send message: ${chatMessage.toMap()}');

      await FirebaseFirestore.instance
          .collection('group_chat')
          .add(chatMessage.toMap());

      print('Message sent successfully');
      messageController.clear();

      scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void dispose() {
    messageController.dispose();
    scrollController.dispose();
  }
}