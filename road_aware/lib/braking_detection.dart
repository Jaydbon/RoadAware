// braking_detection.dart
import 'dart:async';

class BrakingDetector {
  final double brakingThreshold;
  final double accelThreshold;
  final StreamController<bool> _brakeController = StreamController<bool>.broadcast();

  Stream<bool> get brakingStream => _brakeController.stream;

  BrakingDetector({this.brakingThreshold = -5.0, this.accelThreshold = 5.0});

  void updateAcceleration(double axisValue) {
    bool isAggressive = (axisValue < brakingThreshold) | (axisValue > accelThreshold);
    _brakeController.add(isAggressive);
  }

  void dispose() {
    _brakeController.close();
  }
}

class AccelerationDetector {
  final double accelDetector;
  final StreamController<bool> _accelController =
      StreamController<bool>.broadcast();

  Stream<bool> get brakingStream => _accelController.stream;

  AccelerationDetector({this.accelDetector = -5.0});

  void updateAcceleration(double axisValue) {
    bool isAggressive = axisValue < accelDetector;
    _accelController.add(isAggressive);
  }

  void dispose() {
    _accelController.close();
  }
}