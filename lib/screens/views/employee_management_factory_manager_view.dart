// view.dart
import 'package:flutter/material.dart';
import 'package:smartsavior2/utils/colors.dart';
import '../../widgets/bottom_bar.dart';
import '../models/employee_management_factory_manager_model.dart';
import '../controllers/employee_management_factory_manager_controller.dart';

class FactoryManagementPage extends StatefulWidget {
  final String factoryManagerId;

  const FactoryManagementPage({super.key, required this.factoryManagerId});

  @override
  _FactoryManagementPageState createState() => _FactoryManagementPageState();
}

class _FactoryManagementPageState extends State<FactoryManagementPage> with SingleTickerProviderStateMixin {
  late FactoryManagementController _controller;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  List<Person> _safetyPersons = [];
  List<Person> _employees = [];
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = FactoryManagementController(factoryManagerId: widget.factoryManagerId);
    _tabController = TabController(length: 2, vsync: this);
    _loadData();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  Future<void> _loadData() async {
    final safetyPersons = await _controller.loadPersonsByPosition('Safety Person');
    final employees = await _controller.loadPersonsByPosition('Employee');

    setState(() {
      _safetyPersons = safetyPersons;
      _employees = employees;
    });
  }

  void _showAddPersonBottomSheet(BuildContext context, String position) {
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
                        'Add $position',
                        style: TextStyle(
                          color: AppColors().primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.topEnd,
                      child: InkWell(onTap: (){}, child: const Icon(Icons.close)),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Enter ${position.toLowerCase()}'s email",
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
                        onPressed: () async {
                          if (_emailController.text.isNotEmpty) {
                            await _controller.addPerson(_emailController.text, position, context);
                            _emailController.clear();
                            Navigator.of(context).pop();
                            _loadData();
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

  Widget _buildUserList(bool isSafetyPerson) {
    final List<Person> users = isSafetyPerson ? _safetyPersons : _employees;
    final String position = isSafetyPerson ? 'Safety Person' : 'Employee';

    return Stack(
      children: [
        // Positioned(
        //   top: 0,
        //   left: 0,
        //   right: 0,
        //   child: CustomPaint(
        //     painter: TopHillPainter(),
        //     size: Size(MediaQuery.of(context).size.width, 250),
        //   ),
        // ),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search $position',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
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
                    key: Key(person.id),
                    background: Container(
                      color: AppColors().primaryColor,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) async {
                      await _controller.deletePerson(person.id, context);
                      _loadData();
                    },
                    child: Card(
                      color: Colors.white,
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade200)
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        title: Text(
                          person.name,
                          style: TextStyle(
                            color: AppColors().primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          person.email,
                          style: TextStyle(color: AppColors().secondaryColor),
                        ),
                        leading: CircleAvatar(
                          backgroundImage: person.profileImage != null ? NetworkImage(person.profileImage!) : null,
                          backgroundColor: AppColors().primaryColor.withOpacity(0.1),
                          child: person.profileImage == null ? Icon(Icons.person, color: AppColors().primaryColor) : null,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_outlined, color: Colors.red),
                          onPressed: () async {
                            await _controller.deletePerson(person.id, context);
                            _loadData();
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors().primaryColor,
        leading: IconButton(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.arrow_back_outlined, color: Colors.white,)),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(color: Colors.white),
          unselectedLabelStyle: const TextStyle(color: Colors.grey),
          indicator: UnderlineTabIndicator(borderSide: BorderSide(width: 3.0, color: AppColors().secondaryColor)),
          indicatorWeight: 5,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Safety Persons'),
            Tab(text: 'Employees'),
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
              _buildUserList(true),
              _buildUserList(false),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 36,
            child: FloatingActionButton(
              backgroundColor: AppColors().secondaryColor,
              child: Icon(
                Icons.add,
                color: AppColors().primaryColor,
              ),
              onPressed: () {
                if (_tabController.index == 0) {
                  _showAddPersonBottomSheet(context, 'Safety Person');
                } else {
                  _showAddPersonBottomSheet(context, 'Employee');
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
