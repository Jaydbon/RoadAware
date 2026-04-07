import 'package:flutter/material.dart';

import 'screens/route_tracking_screen.dart';
import 'screens/driving_history_screen.dart';
import 'screens/driving_stats_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/user_side_panel.dart';

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

  final ValueNotifier<bool> showTestBrakeButton = ValueNotifier<bool>(false);
  final ValueNotifier<bool> showTestAccelButton = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLeftHandedMode = ValueNotifier<bool>(false);
  final ValueNotifier<int> tripDataVersion = ValueNotifier<int>(0);

  ThemeMode get themeMode => _themeMode;

  void toggleDarkMode(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void toggleTestBrakeButton(bool value) {
    showTestBrakeButton.value = value;
  }

  void toggleTestAccelButton(bool value) {
    showTestAccelButton.value = value;
  }

  void toggleLeftHandedMode(bool value) {
    isLeftHandedMode.value = value;
  }

  void notifyTripDataChanged() {
    tripDataVersion.value = tripDataVersion.value + 1;
  }

  @override
  void dispose() {
    showTestBrakeButton.dispose();
    showTestAccelButton.dispose();
    isLeftHandedMode.dispose();
    tripDataVersion.dispose();
    super.dispose();
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
      home: const AppShell(),
      routes: {
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 1;

  void _openUserPanel() {
    final appState = AggressiveBrakingApp.of(context)!;
    final bool isLeftHanded = appState.isLeftHandedMode.value;

    if (isLeftHanded) {
      _scaffoldKey.currentState?.openDrawer();
    } else {
      _scaffoldKey.currentState?.openEndDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AggressiveBrakingApp.of(context)!;

    return ValueListenableBuilder<bool>(
      valueListenable: appState.isLeftHandedMode,
      builder: (context, isLeftHanded, _) {
        final pages = [
          DrivingHistoryScreen(onOpenUserPanel: _openUserPanel),
          RouteTrackingScreen(onOpenUserPanel: _openUserPanel),
          DrivingStatsScreen(onOpenUserPanel: _openUserPanel),
        ];

        final titles = [
          'Driving History',
          'Route Tracking',
          'Driving Stats',
        ];

        return Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          drawer: isLeftHanded ? const UserSidePanel() : null,
          endDrawer: isLeftHanded ? null : const UserSidePanel(),
          appBar: _currentIndex == 1
              ? null
              : AppBar(
            title: Text(titles[_currentIndex]),
            actions: isLeftHanded
                ? null
                : [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: IconButton(
                  onPressed: _openUserPanel,
                  iconSize: 34,
                  icon: const CircleAvatar(
                    radius: 21,
                    child: Icon(Icons.person, size: 24),
                  ),
                  tooltip: 'Open user menu',
                ),
              ),
            ],
            leading: isLeftHanded
                ? Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButton(
                onPressed: _openUserPanel,
                iconSize: 34,
                icon: const CircleAvatar(
                  radius: 21,
                  child: Icon(Icons.person, size: 24),
                ),
                tooltip: 'Open user menu',
              ),
            )
                : null,
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: _currentIndex,
            onChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }
}