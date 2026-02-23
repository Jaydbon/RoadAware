import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../widgets/app_drawer.dart';
import '../db/repositories.dart';
import '../gps_detection.dart';
import '../braking_detection.dart';

class RouteTrackingScreen extends StatefulWidget {
  static const routeName = '/route';

  const RouteTrackingScreen({super.key});

  @override
  State<RouteTrackingScreen> createState() => _RouteTrackingScreenState();
}

class _RouteTrackingScreenState extends State<RouteTrackingScreen> {
  final TripRepo tripRepo = TripRepo();
  final EventRepo eventRepo = EventRepo();
  final RoutePointRepo routeRepo = RoutePointRepo();
  final ScoreService scoreService = ScoreService();

  final SpeedDetection gps = SpeedDetection();
  final BrakingDetector brakeDetector = BrakingDetector();

  StreamSubscription<Position>? gpsSub;
  StreamSubscription<AccelerometerEvent>? accelSub;
  StreamSubscription<bool>? brakeFlagSub;

  int? tripId;
  bool tracking = false;

  double? lat;
  double? lon;
  double speedKmh = 0;

  int points = 0;
  bool aggressive = false;

  @override
  void initState() {
    super.initState();

    brakeFlagSub = brakeDetector.brakingStream.listen((flag) async {
      setState(() => aggressive = flag);

      if (!tracking) return;
      final id = tripId;
      if (id == null) return;

      if (flag) {
        await eventRepo.logEvent(
          tripId: id,
          type: 'brake',
          severity: 1.0,
          lat: lat,
          lon: lon,
          time: DateTime.now(),
        );
      }
    });
  }

  @override
  void dispose() {
    gpsSub?.cancel();
    accelSub?.cancel();
    brakeFlagSub?.cancel();
    brakeDetector.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final ok = await servicesEnabled();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission / service not enabled')),
        );
      }
      return;
    }

    final id = await tripRepo.startTrip(simulated: false);

    gpsSub = gps.startStream().listen((pos) async {
      final kmh = (pos.speed.isNaN ? 0.0 : pos.speed) * 3.6; // m/s -> km/h

      setState(() {
        lat = pos.latitude;
        lon = pos.longitude;
        speedKmh = kmh < 0 ? 0 : kmh;
      });

      await routeRepo.addPoint(
        tripId: id,
        lat: pos.latitude,
        lon: pos.longitude,
        speed: speedKmh,
        time: pos.timestamp ?? DateTime.now(),
      );

      final c = await routeRepo.pointCount(id);
      if (mounted) setState(() => points = c);
    });

    accelSub = accelerometerEventStream().listen((event) {
      // 这里沿用你现在 brakeTest 的做法：用 event.y 做阈值检测
      brakeDetector.updateAcceleration(event.y);
    });

    setState(() {
      tripId = id;
      tracking = true;
      points = 0;
    });
  }

  Future<void> _stop() async {
    final id = tripId;
    if (id == null) return;

    await gpsSub?.cancel();
    gpsSub = null;
    gps.stopStream();

    await accelSub?.cancel();
    accelSub = null;

    await tripRepo.endTrip(id);

    final score = await scoreService.computeScore(id);
    await tripRepo.updateScore(id, score);

    setState(() {
      tracking = false;
      tripId = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip saved. Score = $score')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final speedText = speedKmh.toStringAsFixed(0);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Route Tracking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Map 占位（你现在没装 maps package）
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(),
              ),
              child: Center(
                child: Text(
                  tracking ? 'Tracking...\n(points: $points)' : 'Map Placeholder',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lat == null ? 'Lat: --' : 'Lat: ${lat!.toStringAsFixed(5)}'),
                Text(lon == null ? 'Lon: --' : 'Lon: ${lon!.toStringAsFixed(5)}'),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: tracking ? _stop : _start,
                    child: Text(tracking ? 'Stop Tracking' : 'Start Tracking'),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 2),
                  ),
                  child: Text(
                    speedText,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: aggressive ? Colors.red : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Icon(aggressive ? Icons.warning : Icons.check_circle),
                const SizedBox(width: 8),
                Text(aggressive ? 'Aggressive event detected' : 'Normal'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}