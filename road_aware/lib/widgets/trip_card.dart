import 'package:flutter/material.dart';
import '../db/repositories.dart';

class TripCard extends StatelessWidget {
  final TripSummary trip;
  final VoidCallback onTap;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = trip.score?.toString() ?? '--';
    final end = trip.endTime == null ? 'In progress' : trip.endTime.toString();

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text('Trip #${trip.id}   Score: $score'),
        subtitle: Text('Start: ${trip.startTime}\nEnd: $end'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}