import 'dart:async';

import 'package:location/location.dart';
import 'package:mycommunity/model/user_location.dart';

class LocationService {

  UserLocation? _currentLocation;

  var location = Location();


  final StreamController<UserLocation> _locationController =
  StreamController<UserLocation>();

  Stream<UserLocation> get locationStream => _locationController.stream;

  LocationService() {
    // Request permission to use location
    location.requestPermission().then((granted) {
      if (granted == true) {
        // If granted listen to the onLocationChanged stream and emit over our controller
        location.onLocationChanged.listen((locationData) {
          if (locationData != null) {
            _locationController.add(UserLocation(
              latitude: locationData.latitude as double,
              longitude: locationData.longitude as double,
            ));
          }
        });
      }
    });
  }

  Future<UserLocation?> getLocation() async {
    try {
      var userLocation = await location.getLocation();
      _currentLocation = UserLocation(
        latitude: userLocation.latitude as double,
        longitude: userLocation.longitude as double,
      );
    } on Exception catch (e) {
      print('Could not get location: ${e.toString()}');
    }

    return _currentLocation;
  }

}