import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyPersonBroadcastsPage extends StatelessWidget {
  final String userId;

  const SafetyPersonBroadcastsPage({Key? key, required this.userId}) : super(key: key);

  void _logError(String operation, dynamic error, StackTrace? stackTrace) {
    print('Error during $operation:');
    print('Error: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }

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
      // First get the current user's factoryManagerId
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          _logError('user stream', userSnapshot.error, userSnapshot.stackTrace);
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

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('broadcasts')
              .where('status', isEqualTo: isCompleted ? 'completed' : 'pending')
              .where('factoryManagerId', isEqualTo: userFactoryManagerId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, broadcastSnapshot) {
            if (broadcastSnapshot.hasError) {
              _logError('broadcasts stream', broadcastSnapshot.error, broadcastSnapshot.stackTrace);
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

            return ListView.builder(
              itemCount: broadcastSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                try {
                  var broadcast = broadcastSnapshot.data!.docs[index];
                  var broadcastData = broadcast.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(broadcastData['message'] ?? 'No message available'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${broadcastData['status'] ?? 'unknown'}'),
                          if (broadcastData['completedBy'] != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(broadcastData['completedBy'])
                                  .get(),
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
                          if (broadcastData['completedAt'] != null)
                            Text('Completed at: ${(broadcastData['completedAt'] as Timestamp).toDate()}'),
                          if (broadcastData['response'] != null)
                            Text('Response: ${broadcastData['response']}'),
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
                  _logError('building list item', e, stackTrace);
                  return ListTile(
                    title: Text('Error loading broadcast item: $e'),
                  );
                }
              },
            );
          },
        );
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
              onPressed: () => _completeBroadcast(
                context,
                broadcastId,
                responseController.text,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeBroadcast(
    BuildContext context,
    String broadcastId,
    String response,
  ) async {
    try {
      print('Starting broadcast completion. BroadcastId: $broadcastId');

      await FirebaseFirestore.instance.collection('broadcasts').doc(broadcastId).update({
        'status': 'completed',
        'completedBy': userId,
        'completedAt': FieldValue.serverTimestamp(),
        'response': response,
      });

      print('Successfully updated broadcast document');
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast marked as completed')),
      );
    } catch (e, stackTrace) {
      _logError('completing broadcast', e, stackTrace);
      
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing broadcast: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}