// views/tools_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/tools_controller.dart';
import '../models/tool_model.dart';
import '../../widgets/bottom_bar.dart';
import 'notifications_page.dart';

class ToolsView extends StatefulWidget {
  final String userId;

  const ToolsView({
    super.key,
    required this.userId,
  });

  @override
  _ToolsViewState createState() => _ToolsViewState();
}

class _ToolsViewState extends State<ToolsView> with SingleTickerProviderStateMixin {
  late ToolsController _controller;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  
  Tool? selectedTool;
  String _name = '';
  String? _selectedLocation;
  String? _selectedRoomId;
  DateTime? _maintenanceDate;
  DateTime? _expirationDate;
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = ToolsController(userId: widget.userId);
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    await _controller.initialize();
    setState(() => _isLoading = false);
  }

  void _handleBack() {
    Navigator.of(context).pop();
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(userId: widget.userId),
      ),
    );
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

  void _submitNewTool() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      await _controller.addTool(
        name: _name,
        location: _selectedLocation!,
        roomId: _selectedRoomId!,
        maintenanceDate: _maintenanceDate!,
        expirationDate: _expirationDate!,
      );

      _tabController.animateTo(0);
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_controller.userLocation == null) {
      return _buildNoAccessScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFC3B5A7),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                if (_controller.canAddTools) _buildTabs(),
                Expanded(
                  child: _controller.canAddTools
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          selectedTool != null ? _buildToolDetail() : _buildToolsList(),
                          _buildAddNewTool(),
                        ],
                      )
                    : (selectedTool != null ? _buildToolDetail() : _buildToolsList()),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFC3B5A7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC3B5A7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handleBack,
        ),
        elevation: 0,
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNoAccessScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFC3B5A7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFC3B5A7),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handleBack,
        ),
        elevation: 0,
      ),
      body: const Center(child: Text('No access to any location')),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFC3B5A7),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: _handleBack,
      ),
      elevation: 0,
      title: const Text(
        'Tools',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: _navigateToNotifications,
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      tabs: const [
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
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Tools',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {}); // Trigger rebuild to update search results
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Tool>>(
            stream: _controller.getToolsStream(_searchController.text),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final tools = snapshot.data!;
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tools.length,
                itemBuilder: (context, index) {
                  return _buildToolCard(tools[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolCard(Tool tool) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.9),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          tool.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${tool.location} - Room ${tool.roomId}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          setState(() {
            selectedTool = tool;
          });
        },
      ),
    );
  }

  Widget _buildToolDetail() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.construction, size: 80, color: Colors.brown),
              const SizedBox(height: 20),
              Text(
                selectedTool!.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
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
    if (!_controller.canAddTools) {
      return const Center(child: Text('You do not have permission to add new tools'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '+ Add Tool',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildRoomDropdown(),
                const SizedBox(height: 16),
                _buildDateFields(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
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
    );
  }

  Widget _buildRoomDropdown() {
    return DropdownButtonFormField<String>(
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
      items: _controller.locationRooms[_controller.userLocation?['name']]?.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList() ?? [],
      onChanged: (value) {
        setState(() {
          _selectedRoomId = value;
          _selectedLocation = _controller.userLocation?['name'];
        });
      },
      validator: (value) => 
        value == null ? 'Please select a room' : null,
    );
  }

  Widget _buildDateFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Expiration Date',
              suffixIcon: const Icon(Icons.calendar_today),
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
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              hintText: 'Maintenance Date',
              suffixIcon: const Icon(Icons.calendar_today),
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
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitNewTool,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC3B5A7),
          minimumSize: const Size(200, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text('Add'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
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
    );
  }
 @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}