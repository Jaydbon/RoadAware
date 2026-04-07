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
    final bool showTestBrake = appState?.showTestBrakeButton ?? false;
    final bool showTestAccel = appState?.showTestAccelButton ?? false;

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
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.developer_mode),
                  title: const Text('Developer Testing'),
                  subtitle: const Text(
                    'Show or hide test buttons on the Route Tracking page',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Show Test Brake Button'),
                  subtitle: const Text(
                    'Display the developer button for simulated braking',
                  ),
                  value: showTestBrake,
                  secondary: const Icon(Icons.car_crash),
                  onChanged: (value) {
                    appState?.toggleTestBrakeButton(value);
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Test Accel Button'),
                  subtitle: const Text(
                    'Display the developer button for simulated acceleration',
                  ),
                  value: showTestAccel,
                  secondary: const Icon(Icons.speed),
                  onChanged: (value) {
                    appState?.toggleTestAccelButton(value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}