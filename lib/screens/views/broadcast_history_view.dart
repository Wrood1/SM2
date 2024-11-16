// broadcast_history_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartsavior2/utils/colors.dart';
import '../../../widgets/bottom_bar.dart';
import '../models/broadcast_history_model.dart';
import '../controllers/broadcast_history_controller.dart';

class BroadcastHistoryPage extends StatefulWidget {
  final String factoryManagerId;

  const BroadcastHistoryPage({super.key, required this.factoryManagerId});

  @override
  _BroadcastHistoryPageState createState() => _BroadcastHistoryPageState();
}

class _BroadcastHistoryPageState extends State<BroadcastHistoryPage> {
  late BroadcastHistoryController _controller;
  final TextEditingController _broadcastSearchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _broadcastSearchQuery = '';
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _controller = BroadcastHistoryController(factoryManagerId: widget.factoryManagerId);
  }

  @override
  void dispose() {
    _broadcastSearchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showBroadcastDialog() {
    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AlertDialog(
    //       title: const Text('Send Broadcast Message'),
    //       content: TextField(
    //         controller: _messageController,
    //         decoration: const InputDecoration(hintText: "Enter your message"),
    //         maxLines: 3,
    //       ),
    //       actions: [
    //         TextButton(
    //           child: const Text('Cancel'),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //         TextButton(
    //           child: const Text('Send'),
    //           onPressed: () {
    //             if (_messageController.text.isNotEmpty) {
    //               _controller.sendBroadcastMessage(_messageController.text, context);
    //               _messageController.clear();
    //               Navigator.of(context).pop();
    //             }
    //           },
    //         ),
    //       ],
    //     );
    //   },
    // );


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // Adjusts for the keyboard
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: AlignmentDirectional.center,
                      child: Text(
                        'Send Broadcast Message',
                        style: TextStyle(
                          color: AppColors().primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: InkWell(onTap: ()=> Navigator.pop(context), child: const Icon(Icons.close)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: "Enter your message",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors().primaryColor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_messageController.text.isNotEmpty) {
                            _controller.sendBroadcastMessage(_messageController.text, context);
                            _messageController.clear();
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors().primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return AppColors().secondaryColor;
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBroadcastList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _controller.getBroadcastsStream(),
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

        var filteredDocs = snapshot.data!.docs.where((doc) {
          var broadcast = doc.data() as Map<String, dynamic>;
          return broadcast['message']
              .toString()
              .toLowerCase()
              .contains(_broadcastSearchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No broadcasts found matching "${_broadcastSearchController.text}"',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) => _buildBroadcastCard(filteredDocs[index]),
        );
      },
    );
  }

  Widget _buildBroadcastCard(DocumentSnapshot doc) {
    var broadcast = doc.data() as Map<String, dynamic>;
    var timestamp = broadcast['timestamp'] as Timestamp?;
    String formattedDate = timestamp != null
        ? '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}'
        : 'No date';

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200)
      ),      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  broadcast['message'] ?? 'No message',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                _buildStatusAndDate(broadcast['status'], formattedDate),

              ],
            ),
            if (broadcast['completedBy'] != null)
              _buildCompletedByInfo(broadcast['completedBy']),
            if (broadcast['completedAt'] !=    null)
              _buildCompletedAtInfo(broadcast['completedAt'], formattedDate),

          ],
        ),
      ),
    );
  }

  Widget _buildStatusAndDate(String? status, String date) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status?.toUpperCase() ?? 'UNKNOWN',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedByInfo(String userId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _controller.getCompletedByUserDetails(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                 Icon(Icons.check_circle, size: 16, color: AppColors().secondaryColor),
                const SizedBox(width: 4),
                Text(
                  'Completed by: ${snapshot.data?['name'] ?? 'Unknown User'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        }
        return const Text(
          'Completed by: Loading...',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        );
      },
    );
  }

  Widget _buildCompletedAtInfo(Timestamp completedAt, String date) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            'Completed at: ${_controller.formatDateTime(completedAt.toDate())}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const Spacer(),
          const SizedBox(width: 8),
          Text(
            date,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors().primaryColor ,
        centerTitle: true,
        leading: IconButton(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.arrow_back_outlined, color: Colors.white,)),
        title: const Text(
          'Broadcast History',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _broadcastSearchController,
                  decoration: InputDecoration(
                    hintText: 'Search broadcasts',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _broadcastSearchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(child: _buildBroadcastList()),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 36,
            child: FloatingActionButton(
              backgroundColor: AppColors().secondaryColor,
              onPressed: _showBroadcastDialog,
              child:  Icon(Icons.add, color: AppColors().primaryColor,),
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