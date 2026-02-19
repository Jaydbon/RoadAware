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
  Future<Position?> getGPS() async {
    bool ok = await servicesEnabled();
    if (!ok) return null;

    Position pos = await Geolocator.getCurrentPosition();

    print(pos.latitude);
    print(pos.longitude);
    print(pos.timestamp);

    return pos; // <-- return the actual data
  }
}

