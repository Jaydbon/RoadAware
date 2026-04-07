import 'package:flutter/material.dart';

import 'screens/route_tracking_screen.dart';
import 'screens/driving_history_screen.dart';
import 'screens/driving_stats_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const AggressiveBrakingApp());
}

class AggressiveBrakingApp extends StatefulWidget {
  const AggressiveBrakingApp({super.key});

  static _AggressiveBrakingAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_AggressiveBrakingAppState>();
  }

  @override
  State<AggressiveBrakingApp> createState() => _AggressiveBrakingAppState();
}

class _AggressiveBrakingAppState extends State<AggressiveBrakingApp> {
  ThemeMode _themeMode = ThemeMode.light;

  bool _showTestBrakeButton = false;
  bool _showTestAccelButton = false;

  ThemeMode get themeMode => _themeMode;
  bool get showTestBrakeButton => _showTestBrakeButton;
  bool get showTestAccelButton => _showTestAccelButton;

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void toggleDarkMode(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void toggleTestBrakeButton(bool value) {
    setState(() {
      _showTestBrakeButton = value;
    });
  }

  void toggleTestAccelButton(bool value) {
    setState(() {
      _showTestAccelButton = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Road Aware',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      routes: {
        RouteTrackingScreen.routeName: (context) => const RouteTrackingScreen(),
        DrivingHistoryScreen.routeName: (context) => const DrivingHistoryScreen(),
        DrivingStatsScreen.routeName: (context) => const DrivingStatsScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      },
      initialRoute: RouteTrackingScreen.routeName,
    );
  }
}