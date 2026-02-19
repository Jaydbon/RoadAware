import 'brakeTest.dart';
import 'gpsTest.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AggressiveBrakingApp());
}

class AggressiveBrakingApp extends StatelessWidget {
  const AggressiveBrakingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final pages = [
    AggressiveBrakingPage(),
    GpsTestPage(),
    PlaceholderPage(title: "Settings"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.speed),
            label: "Braking",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: "GPS",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}