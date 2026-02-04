// main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sensors_plus/sensors_plus.dart';
import 'braking_detection.dart';
import 'package:csv/csv.dart';

void main() {
  runApp(const AggressiveBrakingApp());
}

class AggressiveBrakingApp extends StatelessWidget {
  const AggressiveBrakingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AggressiveBrakingPage(),
    );
  }
}

class AggressiveBrakingPage extends StatefulWidget {
  @override
  State<AggressiveBrakingPage> createState() => _AggressiveBrakingPageState();
}

class _AggressiveBrakingPageState extends State<AggressiveBrakingPage> {
  late BrakingDetector detector;

  StreamSubscription? accelSub;
  StreamSubscription? brakeSub;

  double accelX = 0.0;
  double accelY = 0.0;
  double accelZ = 0.0;

  bool isAggressive = false;
  bool isSimulatingCSV = false;

  @override
  void initState() {
    super.initState();

    detector = BrakingDetector();

    brakeSub = detector.brakingStream.listen((value) {
      setState(() => isAggressive = value);
    });

    accelSub = accelerometerEventStream().listen((event) {
      if (isSimulatingCSV) return; // ignore real data during simulation

      setState(() {
        accelX = event.x;
        accelY = event.y;
        accelZ = event.z;
      });

      detector.updateAcceleration(event.y);
    });
  }

  @override
  void dispose() {
    accelSub?.cancel();
    brakeSub?.cancel();
    detector.dispose();
    super.dispose();
  }

  Future<void> runCsvSimulation() async {
    setState(() => isSimulatingCSV = true);

    final raw = await rootBundle.loadString("assets/brakeData.csv");
    final rows = const CsvToListConverter().convert(raw, eol: "\n");

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      double x = row[1].toDouble();
      double y = row[2].toDouble();
      double z = row[3].toDouble();

      setState(() {
        accelX = x;
        accelY = y;
        accelZ = z;
      });

      detector.updateAcceleration(y);

      await Future.delayed(const Duration(milliseconds: 50));
    }

    setState(() => isSimulatingCSV = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isAggressive ? Colors.red : Colors.white,
      appBar: AppBar(
        title: const Text("Aggressive Braking Detector"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("X: ${accelX.toStringAsFixed(2)} m/s²",
                style: const TextStyle(fontSize: 22)),
            Text("Y: ${accelY.toStringAsFixed(2)} m/s²",
                style: const TextStyle(fontSize: 22)),
            Text("Z: ${accelZ.toStringAsFixed(2)} m/s²",
                style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: isSimulatingCSV ? null : runCsvSimulation,
              child: const Text("Simulate From CSV"),
            ),
          ],
        ),
      ),
    );
  }
}