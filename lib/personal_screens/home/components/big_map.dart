import 'dart:math';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:mycommunity/organisation_screens/campaign/model/campaign.dart';
import 'package:mycommunity/personal_screens/home/components/campaign_detail.dart';
import 'package:mycommunity/personal_screens/home/components/event_detail.dart';
import 'package:mycommunity/personal_screens/home/components/model/geofence_data.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:intl/intl.dart';

class BigMapScreen extends StatefulWidget {
  BigMapScreen();

  @override
  _BigMapScreen createState() => _BigMapScreen();
}

class _BigMapScreen extends State<BigMapScreen> {
  LocationData? _currentLocation;
  GoogleMapController? _mapController;
  List<geoActivity> _activities = [];
  Set<Circle> _circles = {};
  CircleId _circleId = CircleId('userCircle');
  Timer? _timer;
  double _radius = 1000;
  bool _isDraggingMap = false;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startTimer();
  }

  void _startTimer() {
    const duration = Duration(seconds: 5);
    _timer = Timer.periodic(duration, (timer) {
      _buildActivityMarkers();
      print("done build");
    });
  }

  @override
  void dispose() {
    // stop listening to the animation
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _getCurrentLocation() async {
    final location = Location();
    final currentLocation = await location.getLocation();
    setState(() {
      _currentLocation = currentLocation;
      _buildCircle();
    });
  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    if (_currentLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: secBackColor,
      appBar: AppBar(
        leading: const BackButton(color: kPrimaryColor),
        centerTitle: true,
        title: const Text(
          "Activity Discovery Map",
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: kPrimaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        bottomOpacity: 0.0,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
              margin: EdgeInsets.only(top: 10, left: 10, right: 10),
              height: size.height * 0.75,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
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
                          _buildActivityMarkers();
                        },
                        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                          new Factory<OneSequenceGestureRecognizer>(() => new EagerGestureRecognizer(),),
                        ].toSet(),
                        markers: _buildMarkers(),
                        circles: _circles,
                      ),
                    ),
                  ],
                ),
              )
          ),
          Container(
            margin: const EdgeInsets.only(top:5, left: 10, right: 10),
            child: Card(
              elevation: 4, // Adjust the elevation value as needed
              shadowColor: Colors.grey.withOpacity(0.4), // Customize the shadow color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Add the BorderRadius.circular(20)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Slider(
                    value: _radius,
                    min: 100,
                    max: 20000,
                    onChanged: (value) {
                      setState(() {
                        _radius = value;
                        _buildActivityMarkers();
                        _buildCircle();
                      });
                    },
                  ),
                  Text(
                    'Your current radius: ${_formatRadius(_radius)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: kPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]))
       )
      );
  }

  Future<List<geoActivity>> fetchActivitiesWithinRadius(double radius) async {
    List<geoActivity> activities = [];

    try {
      // Fetch campaigns from Firestore
      QuerySnapshot campaignSnapshot = await FirebaseFirestore.instance
          .collection('campaigns')
          .where('is_completed', isEqualTo: false)
          .where('date_time_start', isGreaterThan: DateTime.now())
          .get();

      for (QueryDocumentSnapshot campaignDocument in campaignSnapshot.docs) {
        geoActivity campaign = geoActivity.fromFirestore(campaignDocument);
        campaign.id = campaignDocument.id;
        campaign.type = 'campaign';

        if (calculateDistance(campaign.selectedLocation.latitude, campaign.selectedLocation.longitude) <= radius) {
          double distance = calculateDistance(campaign.selectedLocation.latitude, campaign.selectedLocation.longitude);
          campaign.distance = distance;
          activities.add(campaign);
        }
      }

      // Fetch events from Firestore
      QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('is_completed', isEqualTo: false)
          .where('date_time_start', isGreaterThan: DateTime.now())
          .get();

      for (QueryDocumentSnapshot eventDocument in eventSnapshot.docs) {
        geoActivity event = geoActivity.fromFirestore(eventDocument);
        event.id = eventDocument.id;
        event.type = 'event';

        if (calculateDistance(event.selectedLocation.latitude, event.selectedLocation.longitude) <= radius) {
          double distance = calculateDistance(event.selectedLocation.latitude, event.selectedLocation.longitude);
          event.distance = distance;
          activities.add(event);
        }
      }
    } catch (error) {
      print('Error fetching activities: $error');
    }

    return activities;
  }

  void _buildActivityMarkers() async {
    List<geoActivity> activities = await fetchActivitiesWithinRadius(_radius);
    if(_activities.length != activities.length) {
      setState(() {
        _activities = activities;
      });
      print("Got new update!");
      print("done build");
    }else{
      print("no changes on marker.");
    }
  }

  double calculateDistance(double latitude, double longitude) {
    const double earthRadius = 6371; // Radius of the earth in kilometers

    double userLatitude = _currentLocation!.latitude!;
    double userLongitude = _currentLocation!.longitude!;

    double latDifference = _toRadians(latitude - userLatitude);
    double lonDifference = _toRadians(longitude - userLongitude);

    double a = sin(latDifference / 2) * sin(latDifference / 2) +
        cos(_toRadians(userLatitude)) *
            cos(_toRadians(latitude)) *
            sin(lonDifference / 2) *
            sin(lonDifference / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c; // Distance in kilometers

    double distanceInMeters = distance * 1000; // Convert to meters

    return distanceInMeters;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  String _formatRadius(double radius) {
    if (radius >= 1000) {
      double kmRadius = radius / 1000;
      return kmRadius.toStringAsFixed(1) + 'km';
    } else {
      return radius.toStringAsFixed(0) + 'm';
    }
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    for (geoActivity activity in _activities) {
      LatLng position = LatLng(activity.selectedLocation.latitude, activity.selectedLocation.longitude);

      BitmapDescriptor markerIcon;
      if (activity.type == 'event') {
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      } else if (activity.type == 'campaign') {
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      } else {
        markerIcon = BitmapDescriptor.defaultMarker;
      }

      Marker marker = Marker(
        markerId: MarkerId(activity.id),
        position: position,
        icon: markerIcon,
        onTap: () {
          showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder( // <-- SEE HERE
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25.0),
                ),
              ),
              builder: (context) {
                return SizedBox(
                    height: 350,
                    child: ActivityDetailsWidget(activity: activity)
                );
              }
          );
        },
      );

      markers.add(marker);
    }

    return markers;
  }

  void _buildCircle() {
    _circles.removeWhere((circle) => circle.circleId == _circleId); // Remove the existing circle

    Circle circle = Circle(
      circleId: _circleId,
      center: LatLng(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
      ),
      radius: _radius, // Use the updated radius value
      strokeWidth: 2,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.1),
    );

    setState(() {
      _circles.add(circle); // Add the updated circle to the set
    });
  }
}

class ActivityDetailsWidget extends StatelessWidget {
  final geoActivity activity;

  const ActivityDetailsWidget({required this.activity});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Image.network(
              activity.imageUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Title: ',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(
                          width: size.width*0.55,
                          child: Text(
                            activity.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.normal,
                              color: mainTextColor,
                              fontSize: 14,
                            ),
                          ),
                        )
                      ],
                    ),
                    Text(
                      activity.dateTimeEnd.difference(activity.dateTimeStart).inDays > 0
                          ? DateFormat('dd/MM').format(activity.dateTimeStart) + ' - ' + DateFormat('dd/MM').format(activity.dateTimeEnd)
                          : DateFormat('dd/MM \n hh:mm a').format(activity.dateTimeStart),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Raleway', color: mainTextColor),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Activity type: ',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: activity.type.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.normal,
                              color: mainTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "Distance: ${_formatRadius(activity.distance)}",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, color: mainTextColor, fontFamily: 'SourceSansPro', fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                    padding: EdgeInsets.only(top:25),
                    alignment: Alignment.bottomCenter,
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: size.width*0.5,
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Category: ',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColor,
                                    fontSize: 16,
                                  ),
                                ),
                                TextSpan(
                                  text: activity.category,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.normal,
                                    color: mainTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              if(activity.type == 'event') {
                                Navigator.push(context, MaterialPageRoute(builder: (
                                    context) =>
                                    EventDetailScreen(eventID: activity.id)));
                              }else{
                                Navigator.push(context, MaterialPageRoute(builder: (
                                    context) =>
                                    CampaignDetailScreen(campaignID: activity.id)));
                              }
                            },
                            child: Text(
                              'See detail here!',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                                fontFamily: 'Raleway',
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
  String _formatRadius(double radius) {
    if (radius >= 1000) {
      double kmRadius = radius / 1000;
      return kmRadius.toStringAsFixed(1) + 'km';
    } else {
      return radius.toStringAsFixed(0) + 'm';
    }
  }
}