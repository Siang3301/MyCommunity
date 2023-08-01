import 'dart:async';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mycommunity/personal_screens/home/components/model/geofence_data.dart';
import 'package:geofence_service/geofence_service.dart';

class GeofencingService {
  static final geofenceList = <Geofence>[];
  static User? user = FirebaseAuth.instance.currentUser;
  static String userId = "";
  static StreamController<Activity> activityStreamController = StreamController<Activity>();
  static StreamController<Geofence> geofenceStreamController = StreamController<Geofence>();
  static Timer? geofenceUpdateTimer;
  static Timer? newGeofenceUpdateTimer;

  // Create a [GeofenceService] instance and set options.
  static final geofenceService = GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 60000,
      statusChangeDelayMs: 100,
      useActivityRecognition: true,
      allowMockLocations: true,
      printDevLog: false,
      geofenceRadiusSortType: GeofenceRadiusSortType.DESC);

  static int generateRandomNumber() {
    final random = Random();
    final number = random.nextInt(99999999 - 10000000 + 1) + 10000000;
    return number;
  }

  static bool isUserSignedIn() {
    User? user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  static void startGeofenceUpdates() {

    user = FirebaseAuth.instance.currentUser;

    if (GeofencingService.activityStreamController.isClosed) {
      GeofencingService.activityStreamController = StreamController<Activity>();
    }
    if (GeofencingService.geofenceStreamController.isClosed) {
      GeofencingService.geofenceStreamController = StreamController<Geofence>();
    }

    bool isSignedIn = isUserSignedIn();
    if (isSignedIn) {
      initializeGeofences();
    }
    geofenceUpdateTimer = Timer.periodic(Duration(seconds: 10), (Timer timer) {
      bool isSignedIn = isUserSignedIn();
      if (isSignedIn) {
        initializeGeofences();
      }
    });
    newGeofenceUpdateTimer = Timer.periodic(Duration(minutes: 10), (Timer timer) {
      bool isSignedIn = isUserSignedIn();
      if (isSignedIn) {
        initializeNewGeofencesEvery10Minutes();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      geofenceService.addGeofenceStatusChangeListener(onGeofenceStatusChanged);
      geofenceService.addLocationChangeListener(onLocationChanged);
      geofenceService.addLocationServicesStatusChangeListener(onLocationServicesStatusChanged);
      geofenceService.addActivityChangeListener(onActivityChanged);
      geofenceService.addStreamErrorListener(onError);
      geofenceService.start(geofenceList).catchError(onError);
    });
  }

  static void getCurrentUserID() async {
    if (user != null) {
      userId = user!.uid;
    }
    return null; // No user is currently logged in
  }

  static void initializeGeofences() async {
    try {
      getCurrentUserID();

      // Get user preferences from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users_data').doc(userId).get();
      List<dynamic> userPreferences = List<dynamic>.from(userSnapshot['preferences']);

      // Process event data and add geofences
      List<Geofence> newGeofenceList = [];

      // Retrieve events from Firestore
      QuerySnapshot eventsSnapshot = await FirebaseFirestore.instance.collection('events')
          .where('is_completed', isEqualTo: false)
          .where('date_time_start', isGreaterThan: DateTime.now())
          .get();

      // Process event data and add geofences
      eventsSnapshot.docs.forEach((eventDoc) {
        try {
          final event = geoActivity.fromFirestore(eventDoc);
          event.type = "event";
          event.joinedUserIds = eventDoc['joinedUserIds'];
          String radius = event.geoFenceRadius.toString();

          // Check if event category is included in user's preferences
          if (userPreferences.contains(event.category)) {
            final geofence = Geofence(
              id: eventDoc.id,
              latitude: event.selectedLocation.latitude,
              longitude: event.selectedLocation.longitude,
              radius: [
                GeofenceRadius(id: 'radius_+{$radius}m', length: event.geoFenceRadius),
              ],
              data: event, // Store event data in geofence
            );
            if (event.organizerID != userId) {
              if (!event.joinedUserIds.any((user) => user['userId'] == userId)){
                newGeofenceList.add(geofence);
              }
            }
          }
        } catch (e) {
          print('Error processing event data: $e');
        }
      });

      // Retrieve campaigns from Firestore
      QuerySnapshot campaignsSnapshot = await FirebaseFirestore.instance.collection('campaigns')
          .where('is_completed', isEqualTo: false)
          .where('date_time_start', isGreaterThan: DateTime.now())
          .get();

      // Process campaign data and add geofences
      campaignsSnapshot.docs.forEach((campaignDoc) {
        try {
          final campaign = geoActivity.fromFirestore(campaignDoc);
          campaign.type = "campaign";
          campaign.joinedUserIds = campaignDoc['joinedUserIds'];
          String radius = campaign.geoFenceRadius.toString();

          // Check if campaign category is included in user's preferences
          if (userPreferences.contains(campaign.category)) {
            final geofence = Geofence(
              id: campaignDoc.id,
              latitude: campaign.selectedLocation.latitude,
              longitude: campaign.selectedLocation.longitude,
              radius: [
                GeofenceRadius(id: 'radius_+{$radius}m', length: campaign.geoFenceRadius),
              ],
              data: campaign, // Store campaign data in geofence
            );
            if (!campaign.joinedUserIds.any((user) => user['userId'] == userId)) {
              newGeofenceList.add(geofence);
            }
          }
        } catch (e) {
          print('Error processing campaign data: $e');
        }
      });

      // Update the state with the new geofence list if it's different
      if (geofenceList.length != newGeofenceList.length) {
        geofenceService.removeGeofenceList(geofenceList);
        geofenceList.clear();
        geofenceList.addAll(newGeofenceList);
        geofenceService.addGeofenceList(geofenceList);
        print("List changed");
      } else {
        print("No changes");
      }

      print(geofenceList.length);
    } catch (e) {
      print('Error retrieving geofence data from Firestore: $e');
    }
  }

  static void initializeNewGeofencesEvery10Minutes() async {
    try {
      getCurrentUserID();

      // Get user preferences from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users_data').doc(userId).get();
      List<dynamic> userPreferences = List<dynamic>.from(userSnapshot['preferences']);

      // Process event data and add geofences
      List<Geofence> newGeofenceList = [];

      // Retrieve events from Firestore
      QuerySnapshot eventsSnapshot = await FirebaseFirestore.instance.collection('events')
          .where('is_completed', isEqualTo: false)
          .where('date_time_start', isGreaterThan: DateTime.now())
          .get();

      // Process event data and add geofences
      eventsSnapshot.docs.forEach((eventDoc) {
        try {
          final event = geoActivity.fromFirestore(eventDoc);
          event.type = "event";
          event.joinedUserIds = eventDoc['joinedUserIds'];
          String radius = event.geoFenceRadius.toString();

          // Check if event category is included in user's preferences
          if (userPreferences.contains(event.category)) {
            final geofence = Geofence(
              id: eventDoc.id,
              latitude: event.selectedLocation.latitude,
              longitude: event.selectedLocation.longitude,
              radius: [
                GeofenceRadius(id: 'radius_+{$radius}m', length: event.geoFenceRadius),
              ],
              data: event, // Store event data in geofence
            );
            if (event.organizerID != userId) {
                if (!event.joinedUserIds.any((user) => user['userId'] == userId)){
                  newGeofenceList.add(geofence);
                }
            }
          }
        } catch (e) {
          print('Error processing event data: $e');
        }
      });

      // Retrieve campaigns from Firestore
      QuerySnapshot campaignsSnapshot = await FirebaseFirestore.instance.collection('campaigns')
          .where('is_completed', isEqualTo: false)
          .where('date_time_start', isGreaterThan: DateTime.now())
          .get();

      // Process campaign data and add geofences
      campaignsSnapshot.docs.forEach((campaignDoc) {
        try {
          final campaign = geoActivity.fromFirestore(campaignDoc);
          campaign.type = "campaign";
          campaign.joinedUserIds = campaignDoc['joinedUserIds'];
          String radius = campaign.geoFenceRadius.toString();

          // Check if campaign category is included in user's preferences
          if (userPreferences.contains(campaign.category)) {
            final geofence = Geofence(
              id: campaignDoc.id,
              latitude: campaign.selectedLocation.latitude,
              longitude: campaign.selectedLocation.longitude,
              radius: [
                GeofenceRadius(id: 'radius_+{$radius}m', length: campaign.geoFenceRadius),
              ],
              data: campaign, // Store campaign data in geofence
            );
            if (!campaign.joinedUserIds.any((user) => user['userId'] == userId)) {
              newGeofenceList.add(geofence);
            }
          }
        } catch (e) {
          print('Error processing campaign data: $e');
        }
      });

      //Update every 10 minutes
      geofenceService.removeGeofenceList(geofenceList);
      geofenceList.clear();
      geofenceList.addAll(newGeofenceList);
      geofenceService.addGeofenceList(geofenceList);

      print("Updated every 10 minutes");

      print(geofenceList.length);
    } catch (e) {
      print('Error retrieving geofence data from Firestore: $e');
    }
  }


  static Future<void> storeShownNotification(String userId, int notificationId, String activityId, String activityType, String geofenceStatus, String geofenceDescription) async {
    try {
      // Get the reference to the users_notification collection
      final CollectionReference notificationsCollection =
      FirebaseFirestore.instance.collection('users_data').doc(userId).collection('users_notification');

      // Create a document for the shown notification
      await notificationsCollection.doc(activityId).set({
        'notifiedAt': DateTime.now(),
        'notificationId': notificationId.toString(),
        'activityType': activityType,
        'geofenceStatus': geofenceStatus,
        'geofenceDescription': geofenceDescription
      });
    } catch (e) {
      print('Error storing shown notification: $e');
    }
  }

  static void _showCampaignsNotification(String title, String description, String imageUrl, int id, String campaignId) {
    DateTime now = DateTime.now();

    final notification = NotificationContent( //with image from URL
        id: id,
        channelKey: 'MyCampaigns',
        title: '<b>$title<b>',
        body: description,
        bigPicture: imageUrl,
        largeIcon: imageUrl,
        hideLargeIconOnExpand: true,
        notificationLayout: NotificationLayout.BigText,
        payload: {"campaignId": campaignId}
    );

    _updatePromotedUsersCounter(campaignId, now);
    AwesomeNotifications().createNotification(content: notification);
  }

  // static void _updatePromotedUsersCounter(String campaignId) {
  //   final firestoreInstance = FirebaseFirestore.instance;
  //   final collectionRef = firestoreInstance.collection('campaigns');
  //   final documentRef = collectionRef.doc(campaignId);
  //
  //   firestoreInstance.runTransaction((transaction) async {
  //     final snapshot = await transaction.get(documentRef);
  //     if (snapshot.exists) {
  //       final currentCount = snapshot.data()?['users_promoted'] ?? 0;
  //       final updatedCount = currentCount + 1;
  //       transaction.update(documentRef, {'users_promoted': updatedCount});
  //     } else {
  //       transaction.set(documentRef, {'users_promoted': 1});
  //     }
  //   });
  // }

  static void _updatePromotedUsersCounter(String campaignId, DateTime date) {
    final firestoreInstance = FirebaseFirestore.instance;
    final collectionRef = firestoreInstance.collection('campaigns');
    final documentRef = collectionRef.doc(campaignId);

    firestoreInstance.runTransaction((transaction) async {
      final snapshot = await transaction.get(documentRef);
      if (snapshot.exists) {
        final List<dynamic> usersPromotedList = snapshot.data()?['users_promoted'] ?? [];

        // Convert the dynamic list to a list of maps
        final List<Map<String, dynamic>> updatedUsersPromotedList =
        List<Map<String, dynamic>>.from(usersPromotedList);

        // Check if there is already an entry for the current date
        int index = updatedUsersPromotedList.indexWhere((entry) {
          DateTime entryDate = DateTime.parse(entry['date']);
          return entryDate.year == date.year &&
              entryDate.month == date.month &&
              entryDate.day == date.day;
        });

        if (index != -1) {
          // Increment the count for the existing entry
          final currentCount = updatedUsersPromotedList[index]['count'];
          updatedUsersPromotedList[index]['count'] = currentCount + 1;
        } else {
          // Add a new entry for the current date
          updatedUsersPromotedList.add({'date': date.toString(), 'count': 1});
        }

        transaction.update(documentRef, {'users_promoted': updatedUsersPromotedList});
      } else {
        // Create a new entry with the current date
        final usersPromotedList = [{'date': date.toString(), 'count': 1}];
        transaction.set(documentRef, {'users_promoted': usersPromotedList});
      }
    });
  }

  static void _showEventsNotification(String title, String description, String imageUrl, int id, String eventId) {

    final notification = NotificationContent( //with image from URL
        id: id,
        channelKey: 'MyEvents',
        title: '<b>$title<b>',
        body: description,
        bigPicture: imageUrl,
        largeIcon: imageUrl,
        hideLargeIconOnExpand: true,
        notificationLayout: NotificationLayout.BigText,
        payload: {"eventId": eventId}
    );

    AwesomeNotifications().createNotification(content: notification);
  }

  // This function is to be called when the geofence status is changed.
  static Future<void> onGeofenceStatusChanged(
      Geofence geofence,
      GeofenceRadius geofenceRadius,
      GeofenceStatus geofenceStatus,
      Location location) async {

    //generate unique notification id
    int notificationId = generateRandomNumber();

    //If user enters
    //Check if user has already been notified for the activity
    getCurrentUserID();
    bool isNotified = await isActivityIdExist(userId, geofence.id);
    String? currentStatus;

    if(isNotified){
      currentStatus = await getGeofenceStatus(userId, geofence.id);
    }

    if (geofenceStatus == GeofenceStatus.ENTER) {
      if(!isNotified || currentStatus == 'EXIT'){
        final activity = geofence.data as geoActivity;
        double distance = calculateDistance(activity.selectedLocation.latitude, activity.selectedLocation.longitude, location.latitude, location.longitude);
        Random random = Random();
        String message = activity.message;
        String description = random.nextBool() ? "This activity is close to you within ${_formatRadius(distance)}. $message\nClick to view more details!" : "You have an activity close to you within ${_formatRadius(distance)}. $message\nClick to view more details!";
        switch(activity.type){
          case 'event':
            _showEventsNotification(activity.title, description, activity.imageUrl, notificationId, geofence.id);
            await storeShownNotification(userId, notificationId, geofence.id, activity.type, 'ENTER', description);
            print("yes");
            break;

          case 'campaign':
            _showCampaignsNotification(activity.title, description, activity.imageUrl, notificationId, geofence.id);
            await storeShownNotification(userId, notificationId, geofence.id, activity.type, 'ENTER', description);
            print("yes");
            break;
        }
      }
    }else if(geofenceStatus == GeofenceStatus.DWELL){
      //do ntg
      print("you are still in the fence!");
      await updateGeofenceStatus(userId, geofence.id, 'DWELL');
    }else if(geofenceStatus == GeofenceStatus.EXIT){
      //reset the status and allow user to be notified once again
      print("you are out of the fence!");
      await updateGeofenceStatus(userId, geofence.id, 'EXIT');
    }
    //checking
    print('geofence: ${geofence.toJson()}');
    print('geofenceRadius: ${geofenceRadius.toJson()}');
    print('geofenceStatus: ${geofenceStatus.toString()}');
    GeofencingService.geofenceStreamController.sink.add(geofence);
  }


  static double calculateDistance(double latitude, double longitude, double userLatitude, double userLongitude) {
    const double earthRadius = 6371; // Radius of the earth in kilometers

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

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  static String _formatRadius(double radius) {
    if (radius >= 1000) {
      double kmRadius = radius / 1000;
      return kmRadius.toStringAsFixed(1) + 'km';
    } else {
      return radius.toStringAsFixed(0) + 'm';
    }
  }


  // This function is to be called when the activity has changed.
  static void onActivityChanged(Activity prevActivity, Activity currActivity) {
    print('prevActivity: ${prevActivity.toJson()}');
    print('currActivity: ${currActivity.toJson()}');
    GeofencingService.activityStreamController.sink.add(currActivity);
  }

  // This function is to be called when the location has changed.
  static void onLocationChanged(Location location) {
    print('location: ${location.toJson()}');
  }

  // This function is to be called when a location services status change occurs
  // since the service was started.
  static void onLocationServicesStatusChanged(bool status) {
    print('isLocationServicesEnabled: $status');
  }

  // This function is used to handle errors that occur in the service.
  static void onError(error) {
    final errorCode = getErrorCodesFromError(error);
    if (errorCode == null) {
      print('Undefined error: $error');
      return;
    }
    print('ErrorCode: $errorCode');
  }

  //Check if user has been notified.
  static Future<bool> isActivityIdExist(String userId, String activityId) async {
    try {
      // Retrieve the user's notification document
      DocumentSnapshot<Map<String, dynamic>> docSnapshot = await FirebaseFirestore.instance
          .collection('users_data')
          .doc(userId)
          .collection('users_notification')
          .doc(activityId)
          .get();

      // Check if the document exists
      return docSnapshot.exists;
    } catch (e) {
      print('Error checking activityId existence: $e');
      return false;
    }
  }

  //Retrieve geofenceStatus
  static Future<String?> getGeofenceStatus(String userId, String activityId) async {
    try {
      // Retrieve the user's notification document
      DocumentSnapshot<Map<String, dynamic>> docSnapshot = await FirebaseFirestore.instance
          .collection('users_data')
          .doc(userId)
          .collection('users_notification')
          .doc(activityId)
          .get();

      // Check if the document exists and return the geofenceStatus attribute
      if (docSnapshot.exists) {
        Map<String, dynamic>? data = docSnapshot.data();
        String? geofenceStatus = data?['geofenceStatus'];
        return geofenceStatus;
      } else {
        // Document does not exist
        return null;
      }
    } catch (e) {
      print('Error retrieving geofence status: $e');
      return null;
    }
  }

  //update geofenceStatus
  static Future<void> updateGeofenceStatus(String userId, String activityId, String geofenceStatus) async {
    try {
      // Update the geofenceStatus attribute in the user's notification document
      await FirebaseFirestore.instance
          .collection('users_data')
          .doc(userId)
          .collection('users_notification')
          .doc(activityId)
          .update({'geofenceStatus': geofenceStatus});
    } catch (e) {
      print('Error updating geofence status: $e');
    }
  }
}

