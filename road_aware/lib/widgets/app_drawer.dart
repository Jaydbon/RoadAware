import 'package:flutter/material.dart';

import '../screens/route_tracking_screen.dart';
import '../screens/driving_history_screen.dart';
import '../screens/driving_stats_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, String route) {
    Navigator.pop(context); // close drawer
    if (ModalRoute.of(context)?.settings.name == route) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Road Aware',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text('Route Tracking'),
              onTap: () => _go(context, RouteTrackingScreen.routeName),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Driving History'),
              onTap: () => _go(context, DrivingHistoryScreen.routeName),
            ),
            ListTile(
              leading: const Icon(Icons.insights),
              title: const Text('Driving Stats'),
              onTap: () => _go(context, DrivingStatsScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }
}