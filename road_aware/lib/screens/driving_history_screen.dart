import 'package:flutter/material.dart';

import '../db/repositories.dart';
import '../widgets/app_drawer.dart';
import '../widgets/trip_card.dart';
import '../widgets/event_card.dart';

class DrivingHistoryScreen extends StatefulWidget {
  static const routeName = '/history';

  const DrivingHistoryScreen({super.key});

  @override
  State<DrivingHistoryScreen> createState() => _DrivingHistoryScreenState();
}

class _DrivingHistoryScreenState extends State<DrivingHistoryScreen> {
  final TripRepo tripRepo = TripRepo();
  final EventRepo eventRepo = EventRepo();

  List<TripSummary> trips = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await tripRepo.latestTrips(limit: 30);
    if (mounted) {
      setState(() {
        trips = t;
        loading = false;
      });
    }
  }

  Future<void> _openTrip(TripSummary trip) async {
    final events = await eventRepo.eventsForTrip(trip.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Trip #${trip.id}  (score: ${trip.score ?? '--'})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Start: ${trip.startTime}'),
            Text('End: ${trip.endTime ?? '--'}'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const Text('No events recorded.')
            else
              ...events.map((e) => EventCard(event: e)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Driving History')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: trips.length,
          itemBuilder: (context, i) {
            final t = trips[i];
            return TripCard(
              trip: t,
              onTap: () => _openTrip(t),
            );
          },
        ),
      ),
    );
  }
}