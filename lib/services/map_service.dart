// services/map_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapService {
  static final MapService instance = MapService._internal();
  factory MapService() => instance;
  MapService._internal();
  Position? _currentPosition;
  // Default location (Dhaka city center)
  static const double defaultLat = 23.7465;
  static const double defaultLng = 90.3769;
  Position? get currentPosition => _currentPosition;

  /// Initialize location services
  Future<bool> initialize() async {
    try {
      // Check location permission
      final permission = await Permission.location.request();
      if (permission.isDenied) {
        return false;
      }
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }
      // Get current position
      await getCurrentLocation();
      return true;
    } catch (e) {
      print('MapService initialization error: $e');
      return false;
    }
  }

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );
      return _currentPosition;
    } catch (e) {
      print('Error getting current location: $e');
      // Return default location if GPS fails
      _currentPosition = Position(
        latitude: defaultLat,
        longitude: defaultLng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      return _currentPosition;
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Get directions URL (opens in external app)
  String getDirectionsUrl(double lat, double lng) {
    if (_currentPosition != null) {
      return 'https://www.google.com/maps/dir/${_currentPosition!.latitude},${_currentPosition!.longitude}/$lat,$lng';
    }
    return 'https://www.google.com/maps/search/$lat,$lng';
  }

  /// Sort locations by distance from current position
  List<Map<String, dynamic>> sortLocationsByDistance(
      List<Map<String, dynamic>> locations) {
    if (_currentPosition == null) return locations;
    locations.sort((a, b) {
      double distanceA = calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a['lat'],
        a['lng'],
      );
      double distanceB = calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        b['lat'],
        b['lng'],
      );
      return distanceA.compareTo(distanceB);
    });
    return locations;
  }

  /// Get formatted distance string
  String getDistanceString(double lat, double lng) {
    if (_currentPosition == null) return '';
    double distance = calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }

  /// Check if location services are available
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();
    return permission.isGranted;
  }
}
