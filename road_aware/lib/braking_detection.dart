import 'dart:async';

// Optional: A typedef makes the record easier to reference
typedef VehicleState = ({bool isBraking, bool isAccelerating});

class BrakingDetector {
  final double brakingThreshold;
  final double accelThreshold;
  
  // Update the controller to hold the Record type
  final StreamController<VehicleState> _stateController = StreamController<VehicleState>.broadcast();

  Stream<VehicleState> get stateStream => _stateController.stream;

  BrakingDetector({this.brakingThreshold = -5.0, this.accelThreshold = 5.0});

  void updateAcceleration(double axisValue) {
    bool isBrake = (axisValue < brakingThreshold);
    bool isAccel = (axisValue > accelThreshold);
    
    // Add both values at the same time as a single record
    _stateController.add((isBraking: isBrake, isAccelerating: isAccel));
  }

  void dispose() {
    _stateController.close();
  }
}