import 'package:flutter/material.dart';
import 'employee_home_page.dart';
import 'employee_feed_page.dart';
import 'employee_liked_page.dart';
import 'employee_profile_page.dart';
// ignore: depend_on_referenced_packages
import 'package:provider/provider.dart';
import 'providers/liked_jobs_provider.dart';

class EmployeeMainScaffold extends StatefulWidget {
  final int employeeId;
  const EmployeeMainScaffold({Key? key, required this.employeeId})
      : super(key: key);

  @override
  State<EmployeeMainScaffold> createState() => _EmployeeMainScaffoldState();
}

class _EmployeeMainScaffoldState extends State<EmployeeMainScaffold> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  void setTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      EmployeeHomePage(employeeId: widget.employeeId, onTabSelected: setTab),
      EmployeeFeedPage(employeeId: widget.employeeId, onTabSelected: setTab),
      EmployeeLikedPage(employeeId: widget.employeeId, onTabSelected: setTab),
      EmployeeProfilePage(employeeId: widget.employeeId, onTabSelected: setTab),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LikedJobsProvider(employeeId: widget.employeeId),
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: const Color(0xFF0044CC),
          unselectedItemColor: const Color(0xFF33CC33),
          selectedLabelStyle: const TextStyle(color: Color(0xFF0044CC)),
          unselectedLabelStyle: const TextStyle(color: Color(0xFF33CC33)),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Liked'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
