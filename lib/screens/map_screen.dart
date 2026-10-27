import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, LocationService? locationService})
      : _locationService = locationService;

  final LocationService? _locationService;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final LocationService _locationService =
      widget._locationService ?? LocationService();
  Position? _position;
  bool _loading = false;
  String? _message;

  Future<void> _findMyLocation() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final position = await _locationService
          .getCurrentLocation()
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _position = position;
        if (position == null) {
          _message =
              'Location is unavailable. Turn on device location and allow access while using the app.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = 'Location could not be read. Check your device settings.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    return Scaffold(
      appBar: AppBar(title: const Text('Your location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your location is shown on this device only and is not saved to your profile. Hospital and donor map listings are not connected yet.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _findMyLocation,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_loading ? 'Finding location…' : 'Find my location'),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: position == null
                ? const Center(
                    child: Icon(Icons.map_outlined, size: 64),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(position.latitude, position.longitude),
                      zoom: 14,
                    ),
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('current-location'),
                        position: LatLng(position.latitude, position.longitude),
                        infoWindow: const InfoWindow(title: 'Your location'),
                      ),
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
