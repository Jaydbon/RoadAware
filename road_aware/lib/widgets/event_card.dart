import 'package:flutter/material.dart';
import '../db/repositories.dart';

class EventCard extends StatelessWidget {
  final EventRow event;

  const EventCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final isBrake = event.type == 'brake';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatType(event.type),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            Text('Time: ${event.time}'),

            if (event.lat != null && event.lon != null)
              Text(
                'Location: ${event.lat!.toStringAsFixed(5)}, ${event.lon!.toStringAsFixed(5)}',
              ),

            const SizedBox(height: 6),

            Row(
              children: [
                Icon(
                  isBrake ? Icons.warning : Icons.circle,
                  color: isBrake ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 6),
                Text(
                  _riskText(event.severity),
                  style: TextStyle(
                    color: isBrake ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatType(String type) {
    switch (type) {
      case 'brake':
        return 'Hard Braking';
      case 'accel':
        return 'Aggressive Acceleration';
      case 'overspeed':
        return 'Overspeed';
      case 'turn':
        return 'Sharp Turn';
      default:
        return type;
    }
  }

  String _riskText(double? severity) {
    if (severity == null) return 'Risk: Medium';
    if (severity > 2) return 'Risk: Extremely High';
    if (severity > 1) return 'Risk: High';
    return 'Risk: Moderate';
  }
}