import 'package:geolocator/geolocator.dart';

Future<bool> requestLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return false;
  }

  return true;
}


Future<bool> servicesEnabled() async {
  bool granted = await requestLocationPermission();
  if (!granted) return false;

  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    return false;
  }

  return true;
}



class SpeedDetection {
  Stream<Position>? _positionStream;

  Stream<Position> startStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // update on every movement
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: settings);
    return _positionStream!;
  }

  void stopStream() {
    _positionStream = null;
  }
}


