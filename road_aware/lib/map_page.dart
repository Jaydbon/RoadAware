import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:csv/csv.dart';
import 'gps_detection.dart';
import 'braking_detection.dart';
import 'map_widget.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final SpeedDetection _gps = SpeedDetection();
  final BrakingDetector _brakeDetector = BrakingDetector();

  StreamSubscription<Position>? _gpsSub;
  StreamSubscription<bool>? _brakeSub;
  StreamSubscription? _accelSub;

  LatLng? _currentPosition;
  final List<LatLng> _routePoints = [];
  final List<LatLng> _brakePoints = [];

  bool _isTracking = false;
  bool _isRecording = false;
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _brakeSub?.cancel();
    _gpsSub?.cancel();
    _brakeDetector.dispose();
    _gps.stopStream();
    super.dispose();
  }

  Future<void> _startTracking() async {
    final bool ok = await servicesEnabled();
    if (!ok) {
      _showSnack("Location permission or service unavailable.");
      return;
    }

    final Stream<Position> stream = _gps.startStream();

    _gpsSub = stream.listen((Position pos) {
      final LatLng point = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentPosition = point;
        if (_isRecording) _routePoints.add(point);
      });
    });

    _brakeSub = _brakeDetector.brakingStream.listen((bool isBraking) {
      if (isBraking && _isRecording && _currentPosition != null) {
        setState(() => _brakePoints.add(_currentPosition!));
      }
    });

    _accelSub = accelerometerEventStream().listen((event) {
      if (!_isSimulating) _brakeDetector.updateAcceleration(event.y);
    });

    setState(() => _isTracking = true);
  }

  void _stopTracking() {
    _gpsSub?.cancel();
    _gpsSub = null;
    _accelSub?.cancel();
    _accelSub = null;
    _brakeSub?.cancel();
    _brakeSub = null;
    _gps.stopStream();
    setState(() {
      _isTracking = false;
      _isRecording = false;
    });
  }

  void _startRoute() {
    setState(() {
      _routePoints.clear();
      _brakePoints.clear();
      if (_currentPosition != null) _routePoints.add(_currentPosition!);
      _isRecording = true;
    });
    _showSnack("Route started – drive to trace your path.");
  }

  void _endRoute() {
    setState(() => _isRecording = false);
    _showSnack("Route ended. ${_routePoints.length} points recorded.");
  }

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
      _brakePoints.clear();
    });
  }

  Future<void> _startSimulation() async {
    if (_isSimulating) return;

    _gpsSub?.cancel();
    _gpsSub = null;
    _gps.stopStream();

    setState(() {
      _isTracking = false;
      _isSimulating = true;
      _isRecording = true;
      _routePoints.clear();
      _brakePoints.clear();
    });

    _showSnack("Simulating route…");

    final String gpsRaw = await rootBundle.loadString("assets/gpsData.csv");
    final List<List<dynamic>> gpsRows =
    const CsvToListConverter().convert(gpsRaw, eol: "\n");

    final String brakeRaw =
    await rootBundle.loadString("assets/brakeData.csv");
    final List<List<dynamic>> brakeRows =
    const CsvToListConverter().convert(brakeRaw, eol: "\n");

    final int length =
    gpsRows.length < brakeRows.length ? gpsRows.length : brakeRows.length;

    for (int i = 1; i < length; i++) {
      if (!_isSimulating) break;

      final LatLng point = LatLng(
        (gpsRows[i][1] as num).toDouble(),
        (gpsRows[i][2] as num).toDouble(),
      );
      final double accelY = (brakeRows[i][2] as num).toDouble();

      _brakeDetector.updateAcceleration(accelY);

      final bool isBraking = accelY < _brakeDetector.brakingThreshold ||
          accelY > _brakeDetector.accelThreshold;

      setState(() {
        _currentPosition = point;
        _routePoints.add(point);
        if (isBraking) _brakePoints.add(point);
      });

      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (_isSimulating) {
      setState(() {
        _isSimulating = false;
        _isRecording = false;
      });
      _showSnack(
        "Simulation complete. ${_routePoints.length} points, "
            "${_brakePoints.length} braking event${_brakePoints.length == 1 ? '' : 's'}.",
      );
    }
  }

  void _stopSimulation() {
    setState(() {
      _isSimulating = false;
      _isRecording = false;
    });
    _showSnack("Simulation stopped.");
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Map"),
        actions: [
          IconButton(
            icon: Icon(_isTracking ? Icons.gps_fixed : Icons.gps_off),
            tooltip: _isTracking ? "Stop GPS" : "Start GPS",
            onPressed: _isTracking ? _stopTracking : _startTracking,
          ),
          if (_routePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: "Clear route",
              onPressed: _clearRoute,
            ),
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            currentPosition: _currentPosition,
            routePoints: _routePoints,
            brakePoints: _brakePoints,
            isRecording: _isRecording,
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _InfoOverlay(
              position: _currentPosition,
              pointCount: _routePoints.length,
              brakeCount: _brakePoints.length,
              isRecording: _isRecording,
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording && !_isSimulating)
                  FloatingActionButton.extended(
                    heroTag: "start_route",
                    onPressed: _isTracking ? _startRoute : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Start Route"),
                    backgroundColor: _isTracking ? Colors.green : Colors.grey,
                  )
                else if (_isRecording && !_isSimulating)
                  FloatingActionButton.extended(
                    heroTag: "end_route",
                    onPressed: _endRoute,
                    icon: const Icon(Icons.stop),
                    label: const Text("End Route"),
                    backgroundColor: Colors.red,
                  ),
                const SizedBox(width: 16),
                if (!_isSimulating && !_isRecording)
                  FloatingActionButton.extended(
                    heroTag: "simulate",
                    onPressed: _startSimulation,
                    icon: const Icon(Icons.route),
                    label: const Text("Simulate"),
                    backgroundColor: Colors.orange,
                  )
                else if (_isSimulating)
                  FloatingActionButton.extended(
                    heroTag: "stop_sim",
                    onPressed: _stopSimulation,
                    icon: const Icon(Icons.stop),
                    label: const Text("Stop Sim"),
                    backgroundColor: Colors.deepOrange,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoOverlay extends StatelessWidget {
  final LatLng? position;
  final int pointCount;
  final int brakeCount;
  final bool isRecording;

  const _InfoOverlay({
    required this.position,
    required this.pointCount,
    required this.brakeCount,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (position != null) ...[
            Text("Lat: ${position!.latitude.toStringAsFixed(5)}",
                style: const TextStyle(fontSize: 13)),
            Text("Lon: ${position!.longitude.toStringAsFixed(5)}",
                style: const TextStyle(fontSize: 13)),
          ] else
            const Text("Waiting for GPS…",
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          if (isRecording) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.red),
                  ),
                  const SizedBox(width: 4),
                  Text("Recording · $pointCount pts",
                      style:
                      const TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
            ),
            if (brakeCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      "$brakeCount braking event${brakeCount == 1 ? '' : 's'}",
                      style: const TextStyle(
                          fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}