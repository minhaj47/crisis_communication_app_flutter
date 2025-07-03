// screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/map_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapService _mapService = MapService();
  final MapController _mapController = MapController();
  bool _isLoading = true;
  bool _showMap = false;

  List<Map<String, dynamic>> _emergencyLocations = [
    {
      'name': 'Community Center',
      'type': 'shelter',
      'lat': 23.7465,
      'lng': 90.3769,
      'description': 'Emergency shelter with capacity for 200 people',
    },
    {
      'name': 'Main Mosque',
      'type': 'water',
      'lat': 23.7515,
      'lng': 90.3619,
      'description': 'Water distribution point',
    },
    {
      'name': 'Medical Center',
      'type': 'medical',
      'lat': 23.7415,
      'lng': 90.3819,
      'description': 'Emergency medical services available',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);

    bool initialized = await _mapService.initialize();

    if (initialized) {
      // Sort locations by distance
      _emergencyLocations =
          _mapService.sortLocationsByDistance(_emergencyLocations);
    }

    setState(() {
      _isLoading = false;
      _showMap = initialized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Map'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() => _showMap = !_showMap);
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map or placeholder
                Container(
                  height: 300,
                  child: _showMap ? _buildMap() : _buildMapPlaceholder(),
                ),

                // Emergency locations list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _emergencyLocations.length,
                    itemBuilder: (context, index) {
                      final location = _emergencyLocations[index];
                      return _buildLocationCard(location);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _showMap
          ? FloatingActionButton(
              onPressed: _centerMapOnUser,
              child: Icon(Icons.my_location),
              backgroundColor: Colors.green[600],
            )
          : null,
    );
  }

  Widget _buildMap() {
    final userPosition = _mapService.currentPosition;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: userPosition != null
            ? LatLng(userPosition.latitude, userPosition.longitude)
            : LatLng(MapService.defaultLat, MapService.defaultLng),
        zoom: 13.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.emergency_app',
        ),
        MarkerLayer(
          markers: [
            // User location marker
            if (userPosition != null)
              Marker(
                point: LatLng(userPosition.latitude, userPosition.longitude),
                child: Icon(
                  Icons.person_pin_circle,
                  color: Colors.blue,
                  size: 40,
                ),
              ),

            // Emergency location markers
            ..._emergencyLocations.map((location) {
              return Marker(
                point: LatLng(location['lat'], location['lng']),
                child: GestureDetector(
                  onTap: () => _showLocationDetails(location),
                  child: Icon(
                    _getLocationIcon(location['type']),
                    color: _getLocationColor(location['type']),
                    size: 35,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 60, color: Colors.grey[600]),
            SizedBox(height: 10),
            Text(
              'Map Not Available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Location services disabled or unavailable',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _initializeMap,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    IconData icon = _getLocationIcon(location['type']);
    Color iconColor = _getLocationColor(location['type']);
    String distance =
        _mapService.getDistanceString(location['lat'], location['lng']);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 30),
        title: Text(
          location['name'],
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location['description']),
            if (distance.isNotEmpty)
              Text(
                distance,
                style: TextStyle(
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: Icon(Icons.directions),
        onTap: () => _navigateToLocation(location),
      ),
    );
  }

  IconData _getLocationIcon(String type) {
    switch (type) {
      case 'shelter':
        return Icons.home;
      case 'water':
        return Icons.water_drop;
      case 'medical':
        return Icons.medical_services;
      default:
        return Icons.location_on;
    }
  }

  Color _getLocationColor(String type) {
    switch (type) {
      case 'shelter':
        return Colors.blue;
      case 'water':
        return Colors.cyan;
      case 'medical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _centerMapOnUser() {
    final userPosition = _mapService.currentPosition;
    if (userPosition != null) {
      _mapController.move(
        LatLng(userPosition.latitude, userPosition.longitude),
        15.0,
      );
    }
  }

  void _showLocationDetails(Map<String, dynamic> location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(location['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location['description']),
            SizedBox(height: 10),
            Text(
              _mapService.getDistanceString(location['lat'], location['lng']),
              style: TextStyle(
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLocation(location);
            },
            child: Text('Get Directions'),
          ),
        ],
      ),
    );
  }

  void _navigateToLocation(Map<String, dynamic> location) async {
    final url = _mapService.getDirectionsUrl(location['lat'], location['lng']);

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Could not open directions. Please check your internet connection.'),
        ),
      );
    }
  }
}
