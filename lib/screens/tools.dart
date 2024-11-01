import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../widgets/bottom_bar.dart';
import 'notifications_page.dart';

class ToolsPage extends StatefulWidget {
  final String userId;

  // Fix the constructor syntax
  const ToolsPage({
    super.key,  // Changed to use super.key
    required this.userId,
  });  // Removed the old super(key: key) syntax

  @override
  _ToolsPageState createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Tool? selectedTool;
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String? _selectedLocation;
  String? _selectedRoomId;
  DateTime? _maintenanceDate;
  DateTime? _expirationDate;
  Map<String, Map<String, String>> _locationRooms = {};
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  int _currentIndex = 0;
  String? factoryManagerId;
  Map<String, dynamic>? userLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

 Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    await fetchUserRole();
    await fetchLocationData();
    await _fetchRoomData();
    setState(() => _isLoading = false);
  }

  void _resetForm() {
    setState(() {
      _name = '';
      _selectedLocation = null;
      _selectedRoomId = null;
      _maintenanceDate = null;
      _expirationDate = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isMaintenanceDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    
    if (picked != null) {
      setState(() {
        if (isMaintenanceDate) {
          _maintenanceDate = picked;
        } else {
          _expirationDate = picked;
        }
      });
    }
  }

  bool hasAccessToLocation(Map<String, dynamic> locationData) {
    if (widget.userId == locationData['ID']) {
      return true;
    }
    
    if (factoryManagerId != null && locationData['ID'] == factoryManagerId) {
      return true;
    }
    
    return false;
  }



  Future<void> fetchUserRole() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        setState(() {
          factoryManagerId = userData?['factoryManagerId'] as String?;
        });
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }
  }

  Future<void> fetchLocationData() async {
    try {
      final url = Uri.parse('https://smart-64616-default-rtdb.firebaseio.com/.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        for (var entry in data.entries) {
          if (entry.value is Map<String, dynamic>) {
            final locationData = entry.value as Map<String, dynamic>;
            
            if (hasAccessToLocation(locationData)) {
              setState(() {
                userLocation = {
                  ...locationData,
                  'key': entry.key,
                };
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching location data: $e');
    }
  }

  Future<void> _fetchRoomData() async {
    if (userLocation == null) return;

    try {
      Map<String, Map<String, String>> locationRooms = {};
      final location = userLocation!['name'] as String;
      locationRooms[location] = {};

      // Add rooms from the location data
      userLocation!.forEach((key, value) {
        if (key.startsWith('room') && value is Map) {
          final roomId = key;
          final roomName = value['name'] as String? ?? key;
          locationRooms[location]![roomId] = roomName;
        }
      });

      setState(() {
        _locationRooms = locationRooms;
      });
    } catch (e) {
      print('Error processing rooms: $e');
    }
  }

  void _submitNewTool() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      FirebaseFirestore.instance.collection('tools').add({
        'name': _name,
        'location': _selectedLocation,
        'roomId': _selectedRoomId,
        'roomName': _locationRooms[_selectedLocation]?[_selectedRoomId],
        'maintenanceDate': _maintenanceDate,
        'expirationDate': _expirationDate,
        'timestamp': FieldValue.serverTimestamp(),
      }).then((_) {
        _tabController.animateTo(0);
        _resetForm();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding tool: $error'))
        );
      });
    }
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(userId: widget.userId),
      ),
    );
  }

  // Rest of the existing methods remain the same
  // (Including _resetForm, _selectDate, etc.)

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFC3B5A7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userLocation == null) {
      return Scaffold(
        backgroundColor: Color(0xFFC3B5A7),
        body: Center(child: Text('No access to any location')),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFC3B5A7),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      selectedTool != null ? _buildToolDetail() : _buildToolsList(),
                      _buildAddNewTool(),
                    ],
                  ),
                ),
                SizedBox(height: 80),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomBottomBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          if (selectedTool != null)
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => selectedTool = null),
            )
          else
            Icon(Icons.construction, color: Colors.white),
          SizedBox(width: 16),
          Text(
            'Tools',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: _navigateToNotifications,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: 'Tools'),
        Tab(text: 'Add New'),
      ],
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.brown,
    );
  }

  Widget _buildToolsList() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Tools',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tools').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var tools = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final searchTerm = _searchController.text.toLowerCase();
                return data['name'].toString().toLowerCase().contains(searchTerm);
              }).toList();

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  final data = tools[index].data() as Map<String, dynamic>;
                  return _buildToolCard(data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(Map<String, dynamic> data) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.9),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          data['name'] ?? 'Unnamed Tool',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${data['location']} - ${data['roomName']}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          setState(() {
            selectedTool = Tool(
              name: data['name'],
              location: data['location'],
              roomId: data['roomId'],
              expirationDate: (data['expirationDate'] as Timestamp).toDate(),
              maintenanceDate: (data['maintenanceDate'] as Timestamp).toDate(),
              lastUpdate: (data['timestamp'] as Timestamp).toDate(),
            );
          });
        },
      ),
    );
  }

  Widget _buildToolDetail() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.construction, size: 80, color: Colors.brown),
              SizedBox(height: 20),
              Text(
                selectedTool!.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildInfoRow('Location:', selectedTool!.location),
              _buildInfoRow('Room ID:', selectedTool!.roomId),
              _buildInfoRow('Expiration Date:', 
                DateFormat('dd MMM yyyy').format(selectedTool!.expirationDate)),
              _buildInfoRow('Maintenance Date:', 
                DateFormat('dd MMM yyyy').format(selectedTool!.maintenanceDate)),
              _buildInfoRow('Last Update:', 
                DateFormat('dd MMM yyyy').format(selectedTool!.lastUpdate)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewTool() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+ Add Tool',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Tool Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => 
                    value?.isEmpty ?? true ? 'Please enter a tool name' : null,
                  onSaved: (value) => _name = value!,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Location',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  value: _selectedLocation,
                  items: _locationRooms.keys.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value;
                      _selectedRoomId = null;
                    });
                  },
                  validator: (value) => 
                    value == null ? 'Please select a location' : null,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Room',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  value: _selectedRoomId,
                  items: _selectedLocation != null
                    ? _locationRooms[_selectedLocation]!.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList()
                    : [],
                  onChanged: (value) => setState(() => _selectedRoomId = value),
                  validator: (value) => 
                    value == null ? 'Please select a room' : null,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Expiration Date',
                          suffixIcon: Icon(Icons.calendar_today),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, false),
                        controller: TextEditingController(
                          text: _expirationDate != null
                            ? DateFormat('dd MMM yyyy').format(_expirationDate!)
                            : '',
                        ),
                        validator: (value) =>
                          _expirationDate == null ? 'Please select a date' : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Maintenance Date',
                          suffixIcon: Icon(Icons.calendar_today),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, true),
                        controller: TextEditingController(
                          text: _maintenanceDate != null
                            ? DateFormat('dd MMM yyyy').format(_maintenanceDate!)
                            : '',
                        ),
                        validator: (value) =>
                          _maintenanceDate == null ? 'Please select a date' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitNewTool,
                    child: Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFC3B5A7),
                      minimumSize: Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class Tool {
  final String name;
  final String location;
  final String roomId;
  final DateTime expirationDate;
  final DateTime maintenanceDate;
  final DateTime lastUpdate;

  Tool({
    required this.name,
    required this.location,
    required this.roomId,
    required this.expirationDate,
    required this.maintenanceDate,
    required this.lastUpdate,
  });
} 