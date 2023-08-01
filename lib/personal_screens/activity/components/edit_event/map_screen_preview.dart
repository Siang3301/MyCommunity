import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mycommunity/services/constants.dart';

class MapScreenPreview extends StatefulWidget {
  final LatLng onLocationSelected;
  final double geoFenceRadius;

  MapScreenPreview({required this.onLocationSelected, required this.geoFenceRadius});

  @override
  _MapScreenPreview createState() => _MapScreenPreview();
}

class _MapScreenPreview extends State<MapScreenPreview> {
  LocationData? _currentLocation;
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  double _geofenceRadius = 0.0;
  bool _isDraggingMap = false;

  void _onGeofenceRadiusChanged(String value) {
    setState(() {
      _geofenceRadius = double.tryParse(value) ?? 0.0;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.onLocationSelected;
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    final location = Location();
    final currentLocation = await location.getLocation();
    setState(() {
      _currentLocation = currentLocation;
    });
  }

  void _centerSelectedLocation() {
    if (_mapController != null && _selectedLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_selectedLocation!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Container(
      padding: EdgeInsets.all(10),
      height: size.height * 0.6,
      width: size.width * 0.9,
      margin: EdgeInsets.only(bottom: 25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey,
                  width: 1.0,
                ),
              ),
              child: GoogleMap(
                onCameraMoveStarted: () {
                  setState(() {
                    _isDraggingMap = true;
                  });
                },
                onCameraIdle: () {
                  setState(() {
                    _isDraggingMap = false;
                  });
                },
                scrollGesturesEnabled: true,
                myLocationEnabled: true,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation != null
                      ? LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)
                      : widget.onLocationSelected,
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  setState(() {
                    _mapController = controller;
                  });
                },
                markers: _selectedLocation == null
                    ? {}
                    : {
                  Marker(
                    markerId: MarkerId('selectedLocation'),
                    position: _selectedLocation!,
                  ),
                },
                circles: _selectedLocation == null || widget.geoFenceRadius == 0
                    ? {}
                    : {
                  Circle(
                    circleId: CircleId('geofenceRadius'),
                    center: _selectedLocation!,
                    radius: widget.geoFenceRadius,
                    strokeColor: Colors.blue,
                    fillColor: Colors.blue.withOpacity(0.3),
                  ),
                },
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                  new Factory<OneSequenceGestureRecognizer>(() => new EagerGestureRecognizer(),),
                ].toSet(),
              ),
            ),
            Positioned(
              top: 0,
              left: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    mini: true,
                    elevation: 2,
                    highlightElevation: 2,
                    disabledElevation: 0,
                    isExtended: false,
                    heroTag: 'centerButton',
                    onPressed: _centerSelectedLocation,
                    backgroundColor: Colors.white.withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(Icons.center_focus_strong, color: mainTextColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}