import 'package:flutter/material.dart';
import '../db/repositories.dart';
import 'occurrence_map_preview.dart';

class EventCard extends StatefulWidget {
  final EventRow event;

  const EventCard({
    super.key,
    required this.event,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isBrake = event.type == 'brake';
    final hasLocation = event.lat != null && event.lon != null;

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

            if (hasLocation)
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

            if (hasLocation) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showMap = !_showMap;
                  });
                },
                icon: Icon(_showMap ? Icons.map_outlined : Icons.location_on),
                label: Text(_showMap ? 'Hide Map' : 'Show on Map'),
              ),
            ],

            if (_showMap && hasLocation) ...[
              const SizedBox(height: 8),
              OccurrenceMapPreview(
                lat: event.lat!,
                lon: event.lon!,
              ),
            ],
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
      case 'acceleration':
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