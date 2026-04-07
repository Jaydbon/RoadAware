import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = AggressiveBrakingApp.of(context);
    final bool isDark = appState?.themeMode == ThemeMode.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch between light mode and dark mode'),
              value: isDark,
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
              ),
              onChanged: (value) {
                appState?.toggleDarkMode(value);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}