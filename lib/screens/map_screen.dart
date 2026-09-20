import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  GoogleMapController? _controller;
  StreamSubscription<Position>? _positionStream;

  bool _isLoading = true;
  bool _permissionGranted = false;
  bool _gpsEnabled = false;

  LatLng _currentLatLng = const LatLng(3.8480, 11.5021); // fallback (Yaounde)

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStream?.cancel();
    super.dispose();
  }

  // 🔁 Handle app resume (user enables GPS or permission)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initialize();
    }
  }

  // 🚀 MASTER INITIALIZATION
  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    await _checkGps();
    await _requestPermission();

    if (_gpsEnabled && _permissionGranted) {
      await _getInitialLocation();
      _startLiveTracking();
    }

    setState(() => _isLoading = false);
  }

  // 📡 CHECK GPS
  Future<void> _checkGps() async {
    try {
      _gpsEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      _gpsEnabled = false;
    }
  }

  // 🔐 PERMISSION HANDLING (SAFE)
  Future<void> _requestPermission() async {
    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        _permissionGranted = true;
      } else if (status.isPermanentlyDenied) {
        _permissionGranted = false;
        await openAppSettings();
      } else {
        _permissionGranted = false;
      }
    } catch (e) {
      _permissionGranted = false;
    }
  }

  // 📍 GET INITIAL LOCATION (SAFE)
  Future<void> _getInitialLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _updateLocation(pos);
    } catch (e) {
      // fallback already set
    }
  }

  // 🔄 LIVE TRACKING (SAFE STREAM)
  void _startLiveTracking() {
    try {
      _positionStream?.cancel();

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position pos) {
        _updateLocation(pos);
      });
    } catch (e) {
      // ignore stream errors safely
    }
  }

  // 📌 UPDATE LOCATION + MARKERS
  void _updateLocation(Position pos) {
    final latLng = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _currentLatLng = latLng;

      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId("me"),
            position: latLng,
            infoWindow: const InfoWindow(title: "You are here"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
    });

    _controller?.animateCamera(
      CameraUpdate.newLatLng(latLng),
    );
  }

  // 🎮 MAP CREATED
  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  // 🎯 CENTER BUTTON
  void _goToMe() {
    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLatLng, 16),
    );
  }

  // 🔁 RELOAD SYSTEM
  void _retry() {
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Blood4U Map"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),

      floatingActionButton: _buildFABs(),

      body: _buildBody(),
    );
  }

  // 🧠 BODY CONTROLLER (handles all states)
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_gpsEnabled) {
      return _errorScreen(
        icon: Icons.gps_off,
        title: "GPS is OFF",
        buttonText: "Enable GPS",
        onTap: _retry,
      );
    }

    if (!_permissionGranted) {
      return _errorScreen(
        icon: Icons.location_off,
        title: "Location Permission Needed",
        buttonText: "Grant Permission",
        onTap: _retry,
      );
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _currentLatLng,
            zoom: 14,
          ),

          markers: _markers,

          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
        ),

        _bottomInfo(),
      ],
    );
  }

  // ❌ ERROR UI
  Widget _errorScreen({
    required IconData icon,
    required String title,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.redAccent),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  // 📊 BOTTOM PANEL UI
  Widget _bottomInfo() {
    return Positioned(
      bottom: 20,
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black26,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Text(
          "Lat: ${_currentLatLng.latitude.toStringAsFixed(5)}  "
          "Lng: ${_currentLatLng.longitude.toStringAsFixed(5)}",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // 🎯 FLOATING BUTTONS
  Widget _buildFABs() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "me",
          backgroundColor: Colors.redAccent,
          onPressed: _goToMe,
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: "refresh",
          backgroundColor: Colors.black,
          onPressed: _retry,
          child: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}