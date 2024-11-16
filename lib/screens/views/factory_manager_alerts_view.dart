// broadcast_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/factory_manager_alerts_model.dart';
import '../controllers/factory_manager_alerts_controller.dart';

class SafetyPersonBroadcastsPage extends StatelessWidget {
  final String userId;
  final BroadcastController controller = BroadcastController();

  SafetyPersonBroadcastsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5E6D3),
        appBar: AppBar(
          backgroundColor: Colors.brown[300],
          title: const Text('Broadcasts', style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Completed'),
            ],
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildBroadcastList(false),
            _buildBroadcastList(true),
          ],
        ),
      ),
    );
  }

  Widget _buildBroadcastList(bool isCompleted) {
    return StreamBuilder<DocumentSnapshot>(
      stream: controller.getUserStream(userId),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          controller.logError('user stream', userSnapshot.error, userSnapshot.stackTrace);
          return Center(
            child: Text('Error loading user data: ${userSnapshot.error}'),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
        String? userFactoryManagerId = userData['factoryManagerId'];

        if (userFactoryManagerId == null) {
          return const Center(
            child: Text('User factory manager ID not found'),
          );
        }

        return _buildBroadcastStreamBuilder(isCompleted, userFactoryManagerId);
      },
    );
  }

  Widget _buildBroadcastStreamBuilder(bool isCompleted, String factoryManagerId) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.getBroadcastsStream(isCompleted, factoryManagerId),
      builder: (context, broadcastSnapshot) {
        if (broadcastSnapshot.hasError) {
          controller.logError('broadcasts stream', broadcastSnapshot.error, broadcastSnapshot.stackTrace);
          return Center(
            child: Text('Error loading broadcasts: ${broadcastSnapshot.error}'),
          );
        }

        if (!broadcastSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (broadcastSnapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isCompleted ? 'No completed broadcasts' : 'No pending broadcasts',
              style: const TextStyle(fontSize: 16),
            ),
          );
        }

        return _buildBroadcastListView(broadcastSnapshot.data!.docs, isCompleted);
      },
    );
  }

  Widget _buildBroadcastListView(List<QueryDocumentSnapshot> broadcasts, bool isCompleted) {
    return ListView.builder(
      itemCount: broadcasts.length,
      itemBuilder: (context, index) {
        try {
          var broadcast = Broadcast.fromFirestore(broadcasts[index]);
          
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(broadcast.message),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${broadcast.status}'),
                  if (broadcast.completedBy != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: controller.getCompletedByUser(broadcast.completedBy!),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.hasError) {
                          return const Text('Error loading user info');
                        }
                        if (!userSnapshot.hasData) {
                          return const Text('Loading user info...');
                        }
                        
                        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
                        return Text('Completed by: ${userData['name'] ?? 'Unknown user'}');
                      },
                    ),
                  if (broadcast.completedAt != null)
                    Text('Completed at: ${broadcast.completedAt}'),
                  if (broadcast.response != null)
                    Text('Response: ${broadcast.response}'),
                ],
              ),
              trailing: !isCompleted
                  ? IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      onPressed: () => _showCompleteDialog(
                        context,
                        broadcast.id,
                      ),
                    )
                  : null,
            ),
          );
        } catch (e, stackTrace) {
          controller.logError('building list item', e, stackTrace);
          return ListTile(
            title: Text('Error loading broadcast item: $e'),
          );
        }
      },
    );
  }

  void _showCompleteDialog(BuildContext context, String broadcastId) {
    final TextEditingController responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete Broadcast'),
          content: TextField(
            controller: responseController,
            decoration: const InputDecoration(
              hintText: 'Enter your response...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Complete'),
              onPressed: () => controller.completeBroadcast(
                broadcastId,
                userId,
                responseController.text,
                context,
              ),
            ),
          ],
        );
      },
    );
  }
}