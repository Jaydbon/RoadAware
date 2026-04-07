import 'package:flutter/material.dart';

import '../main.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = AggressiveBrakingApp.of(context)!;
    final bool isDark = appState.themeMode == ThemeMode.dark;

    return Scaffold(
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
                appState.toggleDarkMode(value);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ValueListenableBuilder<bool>(
              valueListenable: appState.isLeftHandedMode,
              builder: (context, isLeftHanded, _) {
                return SwitchListTile(
                  title: const Text('Left-handed Mode'),
                  subtitle: const Text(
                    'Move avatar, route status, speed and location to the left side',
                  ),
                  value: isLeftHanded,
                  secondary: const Icon(Icons.front_hand),
                  onChanged: (value) {
                    appState.toggleLeftHandedMode(value);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.developer_mode),
                  title: Text('Developer Testing'),
                  subtitle: Text(
                    'Show or hide test buttons on the Route Tracking page',
                  ),
                ),
                const Divider(height: 1),
                ValueListenableBuilder<bool>(
                  valueListenable: appState.showTestBrakeButton,
                  builder: (context, showTestBrake, _) {
                    return SwitchListTile(
                      title: const Text('Show Test Brake Button'),
                      subtitle: const Text(
                        'Display the developer button for simulated braking',
                      ),
                      value: showTestBrake,
                      secondary: const Icon(Icons.car_crash),
                      onChanged: (value) {
                        appState.toggleTestBrakeButton(value);
                      },
                    );
                  },
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: appState.showTestAccelButton,
                  builder: (context, showTestAccel, _) {
                    return SwitchListTile(
                      title: const Text('Show Test Accel Button'),
                      subtitle: const Text(
                        'Display the developer button for simulated acceleration',
                      ),
                      value: showTestAccel,
                      secondary: const Icon(Icons.speed),
                      onChanged: (value) {
                        appState.toggleTestAccelButton(value);
                      },
                    );
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