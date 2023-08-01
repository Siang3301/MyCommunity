import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/edit_event.dart';
import 'package:mycommunity/personal_screens/activity/components/participant_list.dart';
import 'package:mycommunity/personal_screens/home/components/model/event_all.dart';
import 'package:mycommunity/personal_screens/profile/profile_preview.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:intl/intl.dart';
import 'package:mycommunity/services/dynamic_link.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;


class EventDetailScreen extends StatefulWidget {
  final String eventID;

  const EventDetailScreen({Key? key, required this.eventID}) : super(key: key);
  @override
  _EventDetailScreen createState() => _EventDetailScreen();
}

class _EventDetailScreen extends State<EventDetailScreen> {
  late Future<Event?> _futureEvent;
  GoogleMapController? _mapController;
  String organizerContact = "", organizerName = "", organizerId = "", imageUrl = "", eventName = "", eventAddress = "";
  bool _isDraggingMap = false;
  bool isJoined = false;

  @override
  void initState() {
    super.initState();
    _futureEvent = getEventData(widget.eventID);
  }

  Future<Event?> getEventData(String eventID) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventID)
          .get();

      //check if user has joined
      hasJoinedActivity(eventID, context).then((value) {
        setState(() {
          isJoined = value;
        });
      });

      if (doc.exists) {
        Event event = Event.fromFirestore(doc);
        organizerId = event.organizerID;
        imageUrl = event.imageUrl;
        eventName = event.title;
        eventAddress = event.address;
        return event;
      } else {
        return null;
      }
    } catch (e) {
      print('Error retrieving event data: $e');
      return null;
    }
  }

  void getOrganizerDetail(String organizerID) async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    await db
        .collection('users_data')
        .doc(organizerID)
        .get()
        .then((value) {
      if(mounted) {
        setState(() {
          organizerContact = value['contact'];
          organizerName = value['username'];
        });
      }
    });
  }

  int generateRandomNumber() {
    final random = Random();
    final randomNumber = random.nextInt(90000000) + 10000000;
    return randomNumber;
  }

  Future<void> addUserActivity(String userId, String activityId, DateTime activityStartDateTime, String activityTitle) async {
    final collectionRef = FirebaseFirestore.instance.collection('users_data').doc(userId).collection('user_activities');
    final currentTime = DateTime.now();
    final reminderId = generateRandomNumber();
    await collectionRef.add({
      'activityId': activityId,
      'registerAt': currentTime,
      'activityType' : "event",
      'reminderId': reminderId,
    });
    scheduleReminder(activityStartDateTime, activityTitle, reminderId);
    print('good');
  }

  void scheduleReminder(DateTime activityStartDateTime, String activityTitle, int reminderId) async {
    tz.initializeTimeZones();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    // Calculate the time difference between the activity start date and the current date
    final timeDifference = activityStartDateTime.difference(DateTime.now());
    final isAtLeastOneDayAway = timeDifference.inDays >= 1;

    if (!isAtLeastOneDayAway) {
      print('less than 1 day! will not remind.');
      return; // Do not schedule the reminder if it is less than 1 day away
    }

    // Convert the activityDateTime to the desired time zone
    final location = tz.getLocation('Asia/Kuala_Lumpur');
    final scheduledDate = tz.TZDateTime.from(activityStartDateTime, location);

    // Define the notification details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      color: kPrimaryColor,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    // Schedule the notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      reminderId, // Unique ID for the notification
      'Event Reminder', // Notification title
      'Your event "$activityTitle" is tomorrow!', // Notification content
      scheduledDate.subtract(const Duration(days: 1)), // Schedule date and time
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('reminder set');
  }



  Future<void> joinEvent(String eventId, String userId, String imageURL, String displayName) async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      final eventData = Event.fromFirestore(eventSnapshot);

      if (int.parse(eventData.currentVolunteers)  == int.parse(eventData.volunteer)) {
        Navigator.of(context).pop();
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Activity is Full', style: TextStyle(fontFamily: 'Raleway')),
                content: Text('Sorry, this activity is already full.', style: TextStyle(fontFamily: 'Raleway')),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                  ),
                ],
              );
            },
          );
        return;
      } else if (DateTime.now().isAfter(eventData.dateTimeStart)) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Activity is not available anymore!', style: TextStyle(fontFamily: 'Raleway')),
              content: Text('Sorry, this activity is no longer available.', style: TextStyle(fontFamily: 'Raleway')),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                ),
              ],
            );
          },
        );
        return;
      } else {
        final updatedCurrentVolunteers = int.parse(
            eventData.currentVolunteers) + 1;
        await transaction.update(
          eventRef,
          {
            'joinedUserIds': FieldValue.arrayUnion([
              {'userId': userId, 'imageURL': imageURL, 'displayName': displayName, 'is_archived': false},
            ]),
            'currentVolunteers': updatedCurrentVolunteers.toString(),
          },
        );

        //add UserActivity
        await addUserActivity(userId, widget.eventID, eventData.dateTimeStart, eventData.title);
        // Hide loading dialog and show success dialog
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success', style: TextStyle(fontFamily: 'Raleway')),
              content: Text('You have successfully joined the event!', style: TextStyle(fontFamily: 'Raleway')),
              actions: [
                TextButton(
                  child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home_1',
                          (route) => false,
                      arguments: {'tabIndex': currentIndex},
                    );
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  Future<bool> hasJoinedActivity(String eventId, BuildContext context) async {
    final auth = Provider.of(context)!.auth;
    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    final eventSnapshot = await eventRef.get();
    final joinedUserIds = eventSnapshot.data()?['joinedUserIds'] ?? [];
    return joinedUserIds.map((participant) => participant['userId']).contains(auth.getCurrentUID());
  }

  Future<void> cancelEvent(String eventId, String userId) async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      final eventData = Event.fromFirestore(eventSnapshot);

      final updatedCurrentVolunteers = int.parse(eventData.currentVolunteers) - 1;
      List<dynamic> joinedUserIds = eventData.joinedUserIds;

      int index = -1;
      for (int i = 0; i < joinedUserIds.length; i++) {
        if (joinedUserIds[i]['userId'] == userId) {
          index = i;
          break;
        }
      }
      if (index >= 0) {
        joinedUserIds.removeAt(index);
      }

      await transaction.update(
        eventRef,
        {
          'joinedUserIds': joinedUserIds,
          'currentVolunteers': updatedCurrentVolunteers.toString(),
        },
      );

      //Remove UserActivity
      await removeUserActivity(userId, eventId);

      // Hide loading dialog and show success dialog
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success', style: TextStyle(fontFamily: 'Raleway')),
            content: Text('You have successfully cancelled your participation from the event!', style: TextStyle(fontFamily: 'Raleway')),
            actions: [
              TextButton(
                child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home_1',
                        (route) => false,
                    arguments: {'tabIndex': currentIndex},
                  );
                },
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> markActivityCompleted(String eventID, String userId) async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventID);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      final eventData = Event.fromFirestore(eventSnapshot);

      if (eventData.isCompleted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Activity Already Completed', style: TextStyle(fontFamily: 'Raleway')),
              content: Text('You have already marked this activity as completed.', style: TextStyle(fontFamily: 'Raleway')),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                ),
              ],
            );
          },
        );
        return;
      }

      if (DateTime.now().isBefore(eventData.dateTimeEnd)) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Cannot mark activity as completed', style: TextStyle(fontFamily: 'Raleway')),
              content: Text('Your activity is not completed yet. You cannot mark it as completed.', style: TextStyle(fontFamily: 'Raleway')),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                ),
              ],
            );
          },
        );
        return;
      }

      await transaction.update(
        eventRef,
        {
          'is_completed': true,
          'complete_time': DateTime.now()
        },
      );

      //Add award to the user.
      addAward(eventData, userId);

      // Hide loading dialog and show success dialog
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Activity Completed', style: TextStyle(fontFamily: 'Raleway')),
            content: Text('Congratulations! You have completed the activity.', style: TextStyle(fontFamily: 'Raleway')),
            actions: [
              TextButton(
                child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home_1',
                        (route) => false,
                    arguments: {'tabIndex': currentIndex},
                  );
                },
              ),
            ],
          );
        },
      );
    });
  }

  void addAward(Event eventData, String organizerId) async {
    try {
      // Calculate volunteer time
      DateTime startDateTime = eventData.dateTimeStart;
      DateTime endDateTime = eventData.dateTimeEnd;
      List<dynamic> joinedUserIds = eventData.joinedUserIds;
      final orgRef = FirebaseFirestore.instance.collection('users_data').doc(organizerId);

      int totalVolunteerHours = 0;
      int totalVolunteerMinutes = 0;

      // Calculate the total number of days between start and end dates
      int totalDays = endDateTime.difference(startDateTime).inDays + 1;

      // Calculate volunteer time for each day
      for (int i = 0; i < totalDays; i++) {
        DateTime currentDayStartDateTime =
        DateTime(startDateTime.year, startDateTime.month, startDateTime.day + i, startDateTime.hour, startDateTime.minute);

        DateTime currentDayEndDateTime =
        DateTime(startDateTime.year, startDateTime.month, startDateTime.day + i, endDateTime.hour, endDateTime.minute);

        // Calculate volunteer time for the current day
        Duration duration = currentDayEndDateTime.difference(currentDayStartDateTime);
        totalVolunteerHours += duration.inHours;
        totalVolunteerMinutes += duration.inMinutes.remainder(60);
      }

      // Adjust minutes if they exceed 60
      if (totalVolunteerMinutes >= 60) {
        totalVolunteerHours += totalVolunteerMinutes ~/ 60;
        totalVolunteerMinutes = totalVolunteerMinutes.remainder(60);
      }

      // Update each user's rewards
      for (dynamic userId in joinedUserIds) {
        // Retrieve the user document from Firestore
        DocumentReference userRef = FirebaseFirestore.instance.collection('users_data').doc(userId['userId']);
        DocumentSnapshot userSnapshot = await userRef.get();

        // Retrieve the document data as a map
        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

        // Update total volunteer time
        int previousVolunteerHours = userData['total_volunteer_hours'] ?? 0;
        int previousVolunteerMinutes = userData['total_volunteer_minutes'] ?? 0;

        int userTotalVolunteerHours = totalVolunteerHours + previousVolunteerHours;
        int userTotalVolunteerMinutes = totalVolunteerMinutes + previousVolunteerMinutes;

        // Adjust minutes if they exceed 60
        if (userTotalVolunteerMinutes >= 60) {
          userTotalVolunteerHours += userTotalVolunteerMinutes ~/ 60;
          userTotalVolunteerMinutes = userTotalVolunteerMinutes.remainder(60);
        }

        // Update total participated events
        int totalParticipatedEvents = userData['total_participated_events'] ?? 0;
        totalParticipatedEvents++;

        // Update the user document with the new values
        await userRef.update({
          'total_volunteer_hours': userTotalVolunteerHours,
          'total_volunteer_minutes': userTotalVolunteerMinutes,
          'total_participated_events': totalParticipatedEvents,
        });
      }

      // Update organizer's total organized event number
      DocumentSnapshot orgSnapshot = await orgRef.get();
      Map<String, dynamic> userData = orgSnapshot.data() as Map<String, dynamic>;
      int totalEventOrganized = userData['total_event_organized'] ?? 0;
      totalEventOrganized++;
      await orgRef.update({
        'total_event_organized': totalEventOrganized,
      });

      print("Awarding process done! cheers!");
    } catch (error) {
      print('Error adding reward: $error');
    }
  }

  Future<void> removeUserActivity(String userId, String activityId) async {
    final collectionRef = FirebaseFirestore.instance
        .collection('users_data')
        .doc(userId)
        .collection('user_activities');
    final querySnapshot =
    await collectionRef.where('activityId', isEqualTo: activityId).get();

    if (querySnapshot.docs.isNotEmpty) {
      final userActivityRef =
      collectionRef.doc(querySnapshot.docs.first.id);
      final reminderId = querySnapshot.docs.first.get('reminderId') as int;
      await userActivityRef.delete();

      // Cancel the corresponding reminder
      cancelReminder(reminderId);
    }
  }

  void cancelReminder(int notificationId) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    print('reminder cancelled');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, leading: const BackButton(color: kPrimaryColor), elevation: 0,
          actions: [
            Container(
              width: 30,
              margin: const EdgeInsets.only(right: 10, top: 7,bottom: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.white.withOpacity(0.6),
              ),
              child: Theme(data: Theme.of(context).copyWith(
                  dividerColor: kPrimaryColor,
                  iconTheme: IconThemeData(color: Colors.white)
              ),
                //list if widget in appbar actions
                child:PopupMenuButton<int>(//don't specify icon if you want 3 dot menu
                  color: Colors.white,
                  icon: const Icon(Icons.more_vert, color: Color(0xFF707070)),
                  padding: const EdgeInsets.only(right: 1),
                  onSelected: (item) => onClicked(context, item, organizerId, widget.eventID, imageUrl, eventName, eventAddress, organizerName),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<int>(
                      value: 0,
                      child: Row(
                        children: const [
                          Icon(Icons.share, color: mainTextColor),
                          SizedBox(width: 8),
                          Text("Share Activity",style: TextStyle(color: mainTextColor, fontFamily: 'Raleway', fontSize: 15)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<int>(
                      value: 1,
                      child: Row(
                        children: const [
                          Icon(Icons.report, color: mainTextColor),
                          SizedBox(width: 8),
                          Text("Report activity",style: TextStyle(color: mainTextColor, fontFamily: 'Raleway', fontSize: 15)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<int>(
                      value: 2,
                      child: Row(
                        children: const [
                          Icon(Icons.supervisor_account_sharp, color: mainTextColor),
                          SizedBox(width: 8),
                          Text("Organizer Profile",style: TextStyle(color: mainTextColor, fontFamily: 'Raleway', fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ]
      ),
      body: FutureBuilder<Event?>(
        future: _futureEvent,
        builder: (BuildContext context, AsyncSnapshot<Event?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final event = snapshot.data!;

          //date & time conversion
          DateTime startDateTime = event.dateTimeStart;
          DateTime endDateTime = event.dateTimeEnd;
          String startDate = DateFormat.yMMMMd().format(startDateTime);
          String formattedDateStart = DateFormat('dd MMM yy').format(startDateTime);
          String formattedDateEnd = DateFormat('dd MMM yy').format(endDateTime);

          String timeRange = '${event.dateTimeStart.hour.toString().padLeft(2, '0')}:'
              '${event.dateTimeStart.minute.toString().padLeft(2, '0')} until '
              '${event.dateTimeEnd.hour.toString().padLeft(2, '0')}:'
              '${event.dateTimeEnd.minute.toString().padLeft(2, '0')}';

          //location
          LatLng latLng = LatLng(event.selectedLocation.latitude, event.selectedLocation.longitude);
          getOrganizerDetail(event.organizerID);

          return SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                Container(
                  height: size.height *0.35,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(event.imageUrl),
                        fit: BoxFit.cover,
                      )
                  ),
                ),
                event.organizerID == auth.getCurrentUID() ?
                Positioned(
                   right: 0,
                   child: SafeArea(
                     child:Container(
                       margin: const EdgeInsets.only(top:10, right:10),
                       width: size.width * 0.30,
                       height: size.height * 0.05,
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(12.0),
                         shape: BoxShape.rectangle,
                       ),
                       child:ElevatedButton(
                         onPressed: () {
                           showDoubleConfirmDialog_3(context).then((confirmed) async {
                             if (confirmed) {
                               showDialog(
                                 context: context,
                                 barrierDismissible: false,
                                 builder: (BuildContext context) {
                                   return AlertDialog(
                                     content: Column(
                                       mainAxisSize: MainAxisSize.min,
                                       crossAxisAlignment: CrossAxisAlignment.center,
                                       children: const [
                                         CircularProgressIndicator(),
                                         SizedBox(height: 16),
                                         Text(
                                           "Completing event...",
                                           style: TextStyle(fontFamily: 'Raleway'),
                                         ),
                                       ],
                                     ),
                                   );
                                 },
                               );

                               try {
                                 // Call joinEvent and addUserActivity
                                 await markActivityCompleted(widget.eventID, auth.getCurrentUID());

                               } catch (e) {
                                 // Hide loading dialog and show error dialog
                                 Navigator.of(context).pop();
                                 showDialog(
                                   context: context,
                                   builder: (BuildContext context) {
                                     return AlertDialog(
                                       title: Text('Error', style: TextStyle(fontFamily: 'Raleway')),
                                       content: Text('An error occurred while completing the event.', style: TextStyle(fontFamily: 'Raleway')),
                                       actions: [
                                         TextButton(
                                           child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                                           onPressed: () {
                                             Navigator.of(context).pop();
                                           },
                                         ),
                                       ],
                                     );
                                   },
                                 );
                               }
                             }
                           });
                         },
                         style: ElevatedButton.styleFrom(
                             backgroundColor: kPrimaryColor.withOpacity(0.9),
                         ),
                         child: const Text(
                           "COMPLETE", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                         ),
                       ),
                     ),
                   ),
                ):Container(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: size.height*0.32,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: mainBackColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        ),
                      ),
                        padding: const EdgeInsets.all(25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                    width: size.width*0.60,
                                    child: Text(
                                      event.title,
                                      style: TextStyle(fontSize: 15, fontFamily: 'Raleway', fontWeight: FontWeight.bold, color: kPrimaryColor),
                                    )
                                ),
                                SizedBox(
                                  width: size.width*0.25,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$organizerName', textAlign: TextAlign.end,
                                        style: TextStyle(fontSize: 10, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: mainTextColor),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        '$organizerContact', textAlign: TextAlign.end,
                                        style: TextStyle(fontSize: 10, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: mainTextColor),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 15.0),
                            SizedBox(
                              child:Text(
                                event.description, textAlign: TextAlign.justify,
                                style: TextStyle(fontSize: 10, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor),
                              ),
                            ),
                            const SizedBox(height: 15.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Category:",
                                      style: TextStyle(fontSize: 14, fontFamily: 'Raleway', fontWeight: FontWeight.bold, color: mainTextColor),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      event.category,
                                      style: const TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor),
                                    )
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, color: mainTextColor),
                                    const SizedBox(height: 8),
                                    (startDateTime.year == endDateTime.year && startDateTime.month == endDateTime.month && startDateTime.day == endDateTime.day) ?
                                    Text(
                                      startDate,
                                      style: TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor),
                                    ) :
                                    Text(formattedDateStart + " - " + formattedDateEnd, style: TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor))
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.access_time, color: mainTextColor),
                                    const SizedBox(height: 8),
                                    Text(
                                      timeRange,
                                      style: TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor),
                                    )
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 15.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Volunteering details:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      fontFamily: 'Raleway'
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                        width: size.width*0.70,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('- Volunteer required: ' + event.volunteer, style: TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor) ),
                                            Text(event.volunteeringDetail, style: TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor)),
                                          ],
                                        )
                                    ),
                                    SizedBox(
                                        width: size.width*0.10,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Icon(Icons.people, color: mainTextColor),
                                            SizedBox(height: 5),
                                            Text(
                                              '${event.currentVolunteers}/${event.volunteer}',
                                              style: const TextStyle(
                                                fontFamily: 'Raleway',
                                                color: descColor,
                                                fontSize: 10.0,
                                              ),
                                            ),
                                          ],
                                        )
                                    )
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 15.0),
                            event.locationLink != "" ?
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Location-link:',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "Raleway"
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    event.locationLink,
                                    style: const TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor)
                                ),
                              ],
                            ):
                            Container(),
                            event.locationLink != "" ?
                            const SizedBox(height: 15.0):
                            const SizedBox(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Address:',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "Raleway"
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    event.address,
                                    style: const TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor)
                                ),
                              ],
                            ),
                            const SizedBox(height: 15.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Maps: ',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: "Raleway"
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                    padding: const EdgeInsets.only(top: 10, left: 5, right: 5),
                                    height: size.height * 0.4,
                                    width: size.width * 0.9,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Stack(
                                        children: [
                                          Container(
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                    width: 2.0,
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
                                                    event.selectedLocation.latitude,
                                                    event.selectedLocation.longitude,
                                                  ),
                                                  zoom: 15,
                                                ),
                                                onMapCreated: (controller) {
                                                  setState(() {
                                                    _mapController = controller;
                                                  });
                                                },
                                                markers: event.selectedLocation == null
                                                    ? {}
                                                    : {
                                                  Marker(
                                                    markerId: const MarkerId('selectedLocation'),
                                                    position: latLng,
                                                  ),
                                                },
                                                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
                                                  new Factory<OneSequenceGestureRecognizer>(() => new EagerGestureRecognizer(),),
                                                ].toSet(),
                                              )
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
                                                  onPressed: (){
                                                    if (_mapController != null && event.selectedLocation != null) {
                                                      _mapController!.animateCamera(
                                                        CameraUpdate.newLatLng(
                                                          LatLng(
                                                            event.selectedLocation.latitude,
                                                            event.selectedLocation.longitude,
                                                          ),),
                                                      );
                                                    }
                                                  },
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
                                )
                              ],
                            ),
                            const SizedBox(height: 25),
                            event.organizerID == auth.getCurrentUID() ?
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                event.isCompleted == false?
                                Container(
                                  width: size.width * 0.40,
                                  height: size.height * 0.05,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child:ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditEvent(eventID: widget.eventID)));// Implement edit campaign function
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor
                                    ),
                                    child: const Text(
                                      "EDIT EVENT", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                                    ),
                                  ),
                                ): Container(),
                                Container(
                                  width: size.width * 0.30,
                                  height: size.height * 0.05,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child:ElevatedButton(
                                    onPressed: ()  {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => ParticipantList(activityId: widget.eventID, activityType: 'events')));// Implement edit campaign function
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor
                                    ),
                                    child: const Text(
                                      "DETAIL", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ):
                            isJoined && event.isCompleted == true?
                            Container():
                            isJoined && event.isCompleted == false?
                            Center(
                              child: Container(
                                width: size.width * 0.60,
                                height: size.height * 0.05,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  shape: BoxShape.rectangle,
                                ),
                                child:ElevatedButton(
                                  onPressed: () {
                                    showDoubleConfirmDialog_2(context).then((confirmed) async {
                                      if (confirmed) {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: const [
                                                  CircularProgressIndicator(),
                                                  SizedBox(height: 16),
                                                  Text(
                                                    "Cancelling event...",
                                                    style: TextStyle(fontFamily: 'Raleway'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );

                                        try {
                                          // Call joinEvent and addUserActivity
                                          await cancelEvent(widget.eventID, auth.getCurrentUID());

                                        } catch (e) {
                                          // Hide loading dialog and show error dialog
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Error', style: TextStyle(fontFamily: 'Raleway')),
                                                content: Text('An error occurred while cancelling the event.', style: TextStyle(fontFamily: 'Raleway')),
                                                actions: [
                                                  TextButton(
                                                    child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryColor
                                  ),
                                  child: const Text(
                                    "CANCEL PARTICIPATION", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ):
                            Center(
                              child: Container(
                                width: size.width * 0.60,
                                height: size.height * 0.05,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  shape: BoxShape.rectangle,
                                ),
                                child:ElevatedButton(
                                  onPressed: () {
                                    showDoubleConfirmDialog(context).then((confirmed) async {
                                      if (confirmed) {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: const [
                                                  CircularProgressIndicator(),
                                                  SizedBox(height: 16),
                                                  Text(
                                                    "Joining event...",
                                                    style: TextStyle(fontFamily: 'Raleway'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );

                                        try {
                                          // Call joinEvent and addUserActivity
                                          await joinEvent(widget.eventID, auth.getCurrentUID(), (auth.getUser()?.photoURL).toString(), (auth.getUser()?.displayName).toString());

                                        } catch (e) {
                                          // Hide loading dialog and show error dialog
                                          print(e);
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Error', style: TextStyle(fontFamily: 'Raleway')),
                                                content: Text('An error occurred while joining the event.', style: TextStyle(fontFamily: 'Raleway')),
                                                actions: [
                                                  TextButton(
                                                    child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: kPrimaryColor
                                  ),
                                  child: const Text(
                                    "I WANT TO VOLUNTEER", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            )
                          ],
                        )
                     )
                  ],
                )

              ],
            ),
          );
        }
      )
    );
  }

  Future<void> reportEvent(String eventID, String userId) async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventID);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final eventSnapshot = await transaction.get(eventRef);
      final eventData = Event.fromFirestore(eventSnapshot);

      if (eventData.isCompleted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Activity Already Completed', style: TextStyle(fontFamily: 'Raleway')),
              content: Text('You cannot report this activity!', style: TextStyle(fontFamily: 'Raleway')),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                ),
              ],
            );
          },
        );
        return;
      }

      await transaction.update(
        eventRef,
        {
          'is_reported': true,
        },
      );

      // Hide loading dialog and show success dialog
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Activity Reported', style: TextStyle(fontFamily: 'Raleway')),
            content: Text('You have reported this event, the community admin will further review this activity.', style: TextStyle(fontFamily: 'Raleway')),
            actions: [
              TextButton(
                child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home_1',
                        (route) => false,
                    arguments: {'tabIndex': currentIndex},
                  );
                },
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> onClicked(BuildContext context, int item, String userId, String eventId, String imageUrl,
                        String eventName, String eventAddress, String organizerName) async {
    int count = 0;

    switch(item){
      case 0 :
        final uri = Uri.parse(imageUrl);
        final response = await http.get(uri);
        final bytes = response.bodyBytes;
        final temp = await getTemporaryDirectory();
        final path = '${temp.path}/communityevents.jpg';
        File(path).writeAsBytesSync(bytes);

        DynamicLinkProvider().createEventLink(eventId, eventName, eventAddress, organizerName).then((value) async {
          await Share.shareFiles([path], text: value, subject: 'Make a positive impact on our neighborhood by joining on my event!');
        });
        break;

      case 1 :
        showDoubleConfirmDialog_4(context).then((confirmed) async {
          if (confirmed) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "Reporting event...",
                        style: TextStyle(fontFamily: 'Raleway'),
                      ),
                    ],
                  ),
                );
              },
            );

            try {
              // Call reportEvent
              await reportEvent(eventId, userId);

            } catch (e) {
              // Hide loading dialog and show error dialog
              print(e);
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Error', style: TextStyle(fontFamily: 'Raleway')),
                    content: Text('An error occurred while reporting the event.', style: TextStyle(fontFamily: 'Raleway')),
                    actions: [
                      TextButton(
                        child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          }
        });
        break;

      case 2 :
        Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalProfilePreview(userId: userId)));
        break;
    }
  }

}



Future<bool> showDoubleConfirmDialog(BuildContext context) async {
  bool confirmed = false;
  await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text(
          'Confirm',
          style: TextStyle(fontFamily: 'Raleway'),
        ),
        content: const Text(
          'Are you sure you want to volunteer at this event?',
          style: TextStyle(fontFamily: 'Raleway'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'No, let me think again',
              style: TextStyle(fontFamily: 'Raleway'),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text(
              'Yes, I am sure!',
              style: TextStyle(fontFamily: 'Raleway'),
            ),
            onPressed: () {
              confirmed = true;
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
  return confirmed;
}

Future<bool> showDoubleConfirmDialog_2(BuildContext context) async {
  bool confirmed = false;
  await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text(
          'Confirm',
          style: TextStyle(fontFamily: 'Raleway'),
        ),
        content: const Text(
          'Are you sure you want to cancel your participation at this event?',
          style: TextStyle(fontFamily: 'Raleway'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'No, let me think again',
              style: TextStyle(fontFamily: 'Raleway'),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text(
              'Yes, I am sure!',
              style: TextStyle(fontFamily: 'Raleway'),
            ),
            onPressed: () {
              confirmed = true;
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
  return confirmed;
}

Future<bool> showDoubleConfirmDialog_3(BuildContext context) async {
  bool confirmed = false;
  await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text(
          'Confirm',
          style: TextStyle(fontFamily: 'Raleway'),
        ),
        content: const Text(
          'Are you sure you want to complete this event? All the participants will be awarded after you completely ended the event.',
          style: TextStyle(fontFamily: 'Raleway'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'Not yet',
              style: TextStyle(fontFamily: 'Raleway'),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text(
              'Yes, the activity is completed!',
              style: TextStyle(fontFamily: 'Raleway'),
            ),
            onPressed: () {
              confirmed = true;
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
  return confirmed;
}

Future<bool> showDoubleConfirmDialog_4(BuildContext context) async {
  bool confirmed = false;
  await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text(
          'Confirm',
          style: TextStyle(fontFamily: 'Raleway'),
        ),
        content: const Text(
          'Are you sure you want to report this event? You should only report it if there are potential details of illegal activity.',
          style: TextStyle(fontFamily: 'Raleway'),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text(
              'No',
              style: TextStyle(fontFamily: 'Raleway'),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text(
              'Yes',
              style: TextStyle(fontFamily: 'Raleway'),
            ),
            onPressed: () {
              confirmed = true;
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
  return confirmed;
}