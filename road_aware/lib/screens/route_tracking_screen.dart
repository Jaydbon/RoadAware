import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../main.dart';
import '../db/repositories.dart';
import '../gps_detection.dart';
import '../braking_detection.dart';
import '../map_widget.dart';

class RouteTrackingScreen extends StatefulWidget {
  static const routeName = '/route';

  final VoidCallback onOpenUserPanel;

  const RouteTrackingScreen({
    super.key,
    required this.onOpenUserPanel,
  });

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
  StreamSubscription<({bool isBraking, bool isAccelerating})>? movementStateSub;

  int? tripId;
  bool tracking = false;

  LatLng? currentPosition;
  final List<LatLng> routePoints = [];
  final List<LatLng> brakePoints = [];
  final List<LatLng> accelPoints = [];

  double speedKmh = 0;
  int points = 0;

  bool isBraking = false;
  bool isAccelerating = false;

  String? centerMessage;
  Timer? centerMessageTimer;

  @override
  void initState() {
    super.initState();

    movementStateSub = brakeDetector.stateStream.listen((state) async {
      setState(() {
        isBraking = state.isBraking;
        isAccelerating = state.isAccelerating;

        if (state.isBraking && tracking && currentPosition != null) {
          brakePoints.add(currentPosition!);
        }

        if (state.isAccelerating && tracking && currentPosition != null) {
          accelPoints.add(currentPosition!);
        }
      });

      if (!tracking) return;
      final id = tripId;
      if (id == null) return;

      if (state.isBraking) {
        await eventRepo.logEvent(
          tripId: id,
          type: 'brake',
          severity: 1.0,
          lat: currentPosition?.latitude,
          lon: currentPosition?.longitude,
          time: DateTime.now(),
        );
      } else if (state.isAccelerating) {
        await eventRepo.logEvent(
          tripId: id,
          type: 'acceleration',
          severity: 1.0,
          lat: currentPosition?.latitude,
          lon: currentPosition?.longitude,
          time: DateTime.now(),
        );
      }
    });
  }

  @override
  void dispose() {
    centerMessageTimer?.cancel();
    gpsSub?.cancel();
    accelSub?.cancel();
    movementStateSub?.cancel();
    brakeDetector.dispose();
    gps.stopStream();
    super.dispose();
  }

  void _showCenterMessage(String message) {
    centerMessageTimer?.cancel();

    setState(() {
      centerMessage = message;
    });

    centerMessageTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        centerMessage = null;
      });
    });
  }

  Future<void> _start() async {
    final ok = await servicesEnabled();
    if (!ok) {
      _showCenterMessage('Location permission / service not enabled');
      return;
    }

    final id = await tripRepo.startTrip(simulated: false);

    setState(() {
      routePoints.clear();
      brakePoints.clear();
      accelPoints.clear();
      points = 0;
    });

    gpsSub = gps.startStream().listen((pos) async {
      final kmh = (pos.speed.isNaN ? 0.0 : pos.speed) * 3.6;
      final point = LatLng(pos.latitude, pos.longitude);

      setState(() {
        currentPosition = point;
        routePoints.add(point);
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
      if (mounted) {
        setState(() {
          points = c;
        });
      }
    });

    accelSub = accelerometerEventStream().listen((event) {
      brakeDetector.updateAcceleration(event.y);
    });

    setState(() {
      tripId = id;
      tracking = true;
    });

    _showCenterMessage('Tracking started');
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

    AggressiveBrakingApp.of(context)?.notifyTripDataChanged();

    setState(() {
      tracking = false;
      tripId = null;
    });

    _showCenterMessage('Trip saved. Score = $score');
  }

  Future<void> _runTestBrake() async {
    brakeDetector.updateAcceleration(-10.0);
    await Future.delayed(const Duration(milliseconds: 500));
    brakeDetector.updateAcceleration(0.0);
  }

  Future<void> _runTestAccel() async {
    brakeDetector.updateAcceleration(10.0);
    await Future.delayed(const Duration(milliseconds: 500));
    brakeDetector.updateAcceleration(0.0);
  }

  String get _statusText {
    if (isBraking) return 'Hard Braking Detected!';
    if (isAccelerating) return 'Hard Acceleration Detected!';
    if (tracking) return 'Tracking in progress';
    return 'Ready to start';
  }

  Color _panelBackground(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.black.withOpacity(0.65)
        : Colors.white.withOpacity(0.72);
  }

  Color _primaryTextColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black;
  }

  Color _secondaryTextColor(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : Colors.black87;
  }

  Widget _panel({
    required BuildContext context,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _panelBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildTopBar({
    required BuildContext context,
    required bool isLeftHanded,
    required Color primaryText,
    required Color secondaryText,
    required bool warning,
  }) {
    final statusCard = Expanded(
      child: _panel(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Tracking',
              style: TextStyle(
                color: primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _statusText,
              style: TextStyle(
                color: warning ? Colors.red.shade400 : secondaryText,
                fontWeight: warning ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );

    final avatarButton = GestureDetector(
      onTap: widget.onOpenUserPanel,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _panelBackground(context),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Icon(
            Icons.person,
            size: 28,
            color: primaryText,
          ),
        ),
      ),
    );

    return Row(
      children: isLeftHanded
          ? [
        avatarButton,
        const SizedBox(width: 12),
        statusCard,
      ]
          : [
        statusCard,
        const SizedBox(width: 12),
        avatarButton,
      ],
    );
  }

  Widget _buildSpeedLocationGroup({
    required BuildContext context,
    required bool isLeftHanded,
    required Color primaryText,
    required Color secondaryText,
    required String speedText,
    required String latText,
    required String lonText,
  }) {
    const double overlayWidth = 102;
    const double overlayBottom = 10;
    const double overlaySidePadding = 12;

    return Positioned(
      bottom: overlayBottom,
      left: isLeftHanded ? overlaySidePadding : null,
      right: isLeftHanded ? null : overlaySidePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: overlayWidth,
            height: overlayWidth,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _panelBackground(context),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.35),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  speedText,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'km/h',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: overlayWidth,
            child: _panel(
              context: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      color: secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lat: $latText',
                    style: TextStyle(color: primaryText),
                  ),
                  Text(
                    'Lon: $lonText',
                    style: TextStyle(color: primaryText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperButtons({
    required BuildContext context,
    required bool isLeftHanded,
    required bool showTestBrake,
    required bool showTestAccel,
    required Color primaryText,
  }) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.34,
      left: isLeftHanded ? 12 : null,
      right: isLeftHanded ? null : 12,
      child: _panel(
        context: context,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dev',
              style: TextStyle(
                color: primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (showTestBrake)
              SizedBox(
                width: 108,
                child: ElevatedButton(
                  onPressed: _runTestBrake,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Test Brake',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (showTestBrake && showTestAccel)
              const SizedBox(height: 8),
            if (showTestAccel)
              SizedBox(
                width: 108,
                child: ElevatedButton(
                  onPressed: _runTestAccel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'Test Accel',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AggressiveBrakingApp.of(context)!;

    final String latText = currentPosition == null
        ? '--'
        : currentPosition!.latitude.toStringAsFixed(5);

    final String lonText = currentPosition == null
        ? '--'
        : currentPosition!.longitude.toStringAsFixed(5);

    final String speedText = speedKmh.toStringAsFixed(0);
    final bool warning = isBraking || isAccelerating;

    return ValueListenableBuilder<bool>(
      valueListenable: appState.showTestBrakeButton,
      builder: (context, showTestBrake, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: appState.showTestAccelButton,
          builder: (context, showTestAccel, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: appState.isLeftHandedMode,
              builder: (context, isLeftHanded, _) {
                final bool showDeveloperButtons =
                    showTestBrake || showTestAccel;
                final Color primaryText = _primaryTextColor(context);
                final Color secondaryText = _secondaryTextColor(context);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: MapWidget(
                        currentPosition: currentPosition,
                        routePoints: routePoints,
                        brakePoints: brakePoints,
                        accelPoints: accelPoints,
                        isRecording: tracking,
                      ),
                    ),
                    SafeArea(
                      child: Stack(
                        children: [
                          Positioned(
                            top: 10,
                            left: 12,
                            right: 12,
                            child: _buildTopBar(
                              context: context,
                              isLeftHanded: isLeftHanded,
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              warning: warning,
                            ),
                          ),
                          _buildSpeedLocationGroup(
                            context: context,
                            isLeftHanded: isLeftHanded,
                            primaryText: primaryText,
                            secondaryText: secondaryText,
                            speedText: speedText,
                            latText: latText,
                            lonText: lonText,
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 10,
                            child: Center(
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: ElevatedButton(
                                  onPressed: tracking ? _stop : _start,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    tracking ? 'Stop' : 'Start',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (showDeveloperButtons)
                            _buildDeveloperButtons(
                              context: context,
                              isLeftHanded: isLeftHanded,
                              showTestBrake: showTestBrake,
                              showTestAccel: showTestAccel,
                              primaryText: primaryText,
                            ),
                          if (centerMessage != null)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Center(
                                  child: AnimatedOpacity(
                                    opacity: centerMessage == null ? 0 : 1,
                                    duration:
                                    const Duration(milliseconds: 180),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 36,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _panelBackground(context),
                                        borderRadius:
                                        BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        centerMessage!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: primaryText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}