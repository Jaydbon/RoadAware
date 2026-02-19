import 'dart:async';
import 'package:flutter/material.dart';
import 'gps_detection.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class GpsTestPage extends StatefulWidget {
  const GpsTestPage({super.key});

  @override
  State<GpsTestPage> createState() => _GpsStreamPageState();
}

class _GpsStreamPageState extends State<GpsTestPage> {
  final SpeedDetection gps = SpeedDetection();

  Stream<Position>? stream;
  StreamSubscription<Position>? sub;

  double? lat;
  double? lon;
  DateTime? time;

  bool streaming = false;
  bool simulatingCsv = false;

  // ---------------------------
  // Toggle GPS Live Stream
  // ---------------------------
  Future<void> toggleStream() async {
    if (simulatingCsv) return; // block if CSV sim is running

    if (!streaming) {
      stream = gps.startStream();
      sub = stream!.listen((pos) {
        setState(() {
          lat = pos.latitude;
          lon = pos.longitude;
          time = pos.timestamp;
        });
      });
    } else {
      await sub?.cancel();
      gps.stopStream();
      sub = null;
    }

    setState(() => streaming = !streaming);
  }

  // ---------------------------
  // Run CSV Simulation
  // ---------------------------
  Future<void> runCsvSimulation() async {
    if (streaming) return; // block if live stream is running

    setState(() => simulatingCsv = true);

    final raw = await rootBundle.loadString("assets/brakeData.csv");
    final rows = const CsvToListConverter().convert(raw, eol: "\n");

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      double csvLat = row[1].toDouble();
      double csvLon = row[2].toDouble();

      setState(() {
        lat = csvLat;
        lon = csvLon;
        time = DateTime.now();
      });

      await Future.delayed(const Duration(milliseconds: 200));
    }

    setState(() => simulatingCsv = false);
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GPS Stream + Simulation")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(lat == null ? "Latitude: --" : "Latitude: $lat"),
            Text(lon == null ? "Longitude: --" : "Longitude: $lon"),
            Text(time == null ? "Time: --" : "Time: $time"),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: simulatingCsv ? null : toggleStream,
              child: Text(streaming ? "Stop GPS Stream" : "Start GPS Stream"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: streaming ? null : runCsvSimulation,
              child: const Text("Run CSV Simulation"),
            ),
          ],
        ),
      ),
    );
  }
}