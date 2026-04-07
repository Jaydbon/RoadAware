import 'package:flutter/material.dart';

import '../main.dart';
import '../db/repositories.dart';

class DrivingStatsScreen extends StatefulWidget {
  static const routeName = '/stats';

  final VoidCallback onOpenUserPanel;

  const DrivingStatsScreen({
    super.key,
    required this.onOpenUserPanel,
  });

  @override
  State<DrivingStatsScreen> createState() => _DrivingStatsScreenState();
}

class _DrivingStatsScreenState extends State<DrivingStatsScreen> {
  final TripRepo tripRepo = TripRepo();

  TripSummary? latest;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();

    final appState = AggressiveBrakingApp.of(context);
    appState?.tripDataVersion.addListener(_load);
  }

  @override
  void dispose() {
    final appState = AggressiveBrakingApp.of(context);
    appState?.tripDataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final trips = await tripRepo.latestTrips(limit: 1);
    if (mounted) {
      setState(() {
        latest = trips.isEmpty ? null : trips.first;
        loading = false;
      });
    }
  }

  Widget _legendRow(Color color, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = latest?.score ?? 0;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.85),
            ),
            child: Text(
              '$score',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _legendRow(Colors.green, 'Braking'),
          const SizedBox(height: 10),
          _legendRow(Colors.red, 'Acceleration'),
          const SizedBox(height: 10),
          _legendRow(Colors.yellow, 'Speed'),
          const SizedBox(height: 24),
          Text(
            latest == null ? 'No recent trip data' : 'Latest trip score',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}