import 'package:flutter/material.dart';

import '../db/repositories.dart';
import '../widgets/app_drawer.dart';

class DrivingStatsScreen extends StatefulWidget {
  static const routeName = '/stats';

  const DrivingStatsScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final score = latest?.score ?? 0;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Driving Stats')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
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
              latest == null ? 'No trips yet.' : 'Latest Trip: #${latest!.id}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendRow(Color c, String label) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}