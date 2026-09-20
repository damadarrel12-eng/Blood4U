import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'donor_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'emergency_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final pages = [
    const MapScreen(),
    DonorScreen(),
    const EmergencyScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  final titles = [
    "Map",
    "Donors",
    "Emergency",
    "Profile",
    "Settings"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        centerTitle: true,
      ),

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Donors"),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: "Emergency"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}