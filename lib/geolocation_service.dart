import 'package:geolocator/geolocator.dart';

class QueueLocation {
  const QueueLocation(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class GeolocationService {
  Future<QueueLocation?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return QueueLocation(position.latitude, position.longitude);
    } catch (_) {
      // Location is optional; permission/service/device errors must not block
      // a client from joining the queue.
      return null;
    }
  }
}
