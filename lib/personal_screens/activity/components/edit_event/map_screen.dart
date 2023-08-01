import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mycommunity/services/constants.dart';

class MapScreen extends StatefulWidget {
  final Function(LatLng) onLocationSelected;
  final LatLng initialLocation;

  MapScreen({required this.onLocationSelected, required this.initialLocation});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LocationData? _currentLocation;
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isDraggingMap = false;

  @override
  void initState() {
    super.initState();
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

    if (_currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
        padding: EdgeInsets.all(10),
        height: size.height * 0.4,
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
                    )
                ),
                child : GoogleMap(
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
                    target: LatLng(
                      _currentLocation!.latitude!,
                      _currentLocation!.longitude!,
                    ),
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    setState(() {
                      _mapController = controller;
                    });
                  },
                  onTap: (LatLng latLng) {
                    setState(() {
                      _selectedLocation = latLng;
                    });
                    if (widget.onLocationSelected != null) {
                      widget.onLocationSelected(latLng);
                    }
                  },
                  markers: _selectedLocation == null
                      ? {Marker(markerId: MarkerId('initialLocation'), position: widget.initialLocation)}
                      : {
                    Marker(markerId: MarkerId('selectedLocation'), position: _selectedLocation!),
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
        )
    );
  }
}