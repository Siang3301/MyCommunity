import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mycommunity/organisation_screens/profile/organisation_preview.dart';
import 'package:mycommunity/personal_screens/home/components/model/campaign_all.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:intl/intl.dart';
import 'package:mycommunity/services/dynamic_link.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;


class CampaignDetailScreen extends StatefulWidget {
  final String campaignID;

  const CampaignDetailScreen({Key? key, required this.campaignID}) : super(key: key);
  @override
  _CampaignDetailScreen createState() => _CampaignDetailScreen();
}

class _CampaignDetailScreen extends State<CampaignDetailScreen> {
  late Future<Campaign?> _futureCampaign;
  GoogleMapController? _mapController;
  String organizerContact = "", organizerName = "", organizerId = "", imageUrl = "", campaignName = "", campaignAddress = "";
  bool _isDraggingMap = false;
  bool isJoined = false;

  @override
  void initState() {
    super.initState();
    _futureCampaign = getCampaignData(widget.campaignID);
   // _loadOrganizerDetails();
  }

  @override
  void dispose() {// stop listening to the animation
    _mapController?.dispose();
    super.dispose();
  }

  Future<Campaign?> getCampaignData(String campaignID) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(campaignID)
          .get();

      //check if user has joined
      hasJoinedActivity(campaignID, context).then((value) {
        setState(() {
          isJoined = value;
        });
      });

      if (doc.exists) {
        Campaign campaign = Campaign.fromFirestore(doc);
        organizerId = campaign.organizerID;
        imageUrl = campaign.imageUrl;
        campaignName = campaign.title;
        campaignAddress = campaign.address;
        return campaign;
      } else {
        return null;
      }
    } catch (e) {
      print('Error retrieving campaign data: $e');
      return null;
    }
  }

  void getOrganizerDetail(String organizerID) async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    await db
        .collection('users_data')
        .doc(organizerID)
        .get()
        .then((value){
      if(mounted){
        setState(() {
          organizerContact = value['contact'];
          organizerName = value['organisation_name'];
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
      'activityType' : "campaign",
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
      'Campaign Reminder', // Notification title
      'Your campaign "$activityTitle" is tomorrow!', // Notification content
      scheduledDate.subtract(const Duration(days: 1)), // Schedule date and time
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('reminder set');
  }

  Future<void> joinCampaign(String campaignId, String userId, String imageURL, String displayName) async {
    final eventRef = FirebaseFirestore.instance.collection('campaigns').doc(campaignId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final campaignSnapshot = await transaction.get(eventRef);
      final campaignData = Campaign.fromFirestore(campaignSnapshot);

      if (int.parse(campaignData.currentVolunteers)  == int.parse(campaignData.volunteer)) {
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
      } else if (DateTime.now().isAfter(campaignData.dateTimeStart)) {
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
            campaignData.currentVolunteers) + 1;
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
        await addUserActivity(userId, widget.campaignID, campaignData.dateTimeStart, campaignData.title);

        // Hide loading dialog and show success dialog
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success', style: TextStyle(fontFamily: 'Raleway')),
              content: Text('You have successfully joined the campaign!', style: TextStyle(fontFamily: 'Raleway')),
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
    final eventRef = FirebaseFirestore.instance.collection('campaigns').doc(eventId);
    final eventSnapshot = await eventRef.get();
    final joinedUserIds = eventSnapshot.data()?['joinedUserIds'] ?? [];
    return joinedUserIds.map((participant) => participant['userId']).contains(auth.getCurrentUID());
  }


  Future<void> cancelCampaign(String campaignId, String userId) async {
    final campaignRef = FirebaseFirestore.instance.collection('campaigns').doc(campaignId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final campaignSnapshot = await transaction.get(campaignRef);
      final campaignData = Campaign.fromFirestore(campaignSnapshot);

      final updatedCurrentVolunteers = int.parse(campaignData.currentVolunteers) - 1;
      List<dynamic> joinedUserIds = campaignData.joinedUserIds;

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
        campaignRef,
        {
          'joinedUserIds': joinedUserIds,
          'currentVolunteers': updatedCurrentVolunteers.toString(),
        },
      );

      //Remove UserActivity
      await removeUserActivity(userId, campaignId);

      // Hide loading dialog and show success dialog
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success', style: TextStyle(fontFamily: 'Raleway')),
            content: Text('You have successfully cancelled your participation from the campaign!', style: TextStyle(fontFamily: 'Raleway')),
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
      appBar: AppBar(backgroundColor: Colors.transparent, leading: const BackButton(color: orgMainColor), elevation: 0,
          actions: [
            Container(
              width: 30,
              margin: const EdgeInsets.only(right: 10, top: 7,bottom: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.white.withOpacity(0.6),
              ),
              child: Theme(data: Theme.of(context).copyWith(
                  dividerColor: orgMainColor,
                  iconTheme: IconThemeData(color: Colors.white)
              ),
                //list if widget in appbar actions
                child:PopupMenuButton<int>(//don't specify icon if you want 3 dot menu
                  color: Colors.white,
                  icon: const Icon(Icons.more_vert, color: Color(0xFF707070)),
                  padding: const EdgeInsets.only(right: 1),
                  onSelected: (item) => onClicked(context, item, organizerId, widget.campaignID, imageUrl, campaignName, campaignAddress, organizerName),
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
      body: FutureBuilder<Campaign?>(
        future: _futureCampaign,
        builder: (BuildContext context, AsyncSnapshot<Campaign?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final campaign = snapshot.data!;

          //date & time conversion
          DateTime startDateTime = campaign.dateTimeStart;
          DateTime endDateTime = campaign.dateTimeEnd;
          String startDate = DateFormat.yMMMMd().format(startDateTime);
          String formattedDateStart = DateFormat('dd MMM yy').format(startDateTime);
          String formattedDateEnd = DateFormat('dd MMM yy').format(endDateTime);

          String timeRange = '${campaign.dateTimeStart.hour.toString().padLeft(2, '0')}:'
              '${campaign.dateTimeStart.minute.toString().padLeft(2, '0')} until '
              '${campaign.dateTimeEnd.hour.toString().padLeft(2, '0')}:'
              '${campaign.dateTimeEnd.minute.toString().padLeft(2, '0')}';

          //location
          LatLng latLng = LatLng(campaign.selectedLocation.latitude, campaign.selectedLocation.longitude);
          getOrganizerDetail(campaign.organizerID);

          return SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                Container(
                  height: size.height *0.35,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(campaign.imageUrl),
                        fit: BoxFit.cover,
                      )
                  ),
                ),
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
                                      campaign.title,
                                      style: TextStyle(fontSize: 15, fontFamily: 'Raleway', fontWeight: FontWeight.bold, color: orgMainColor),
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
                                campaign.description, textAlign: TextAlign.justify,
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
                                      campaign.category,
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
                                            Text('- Volunteer required: ' + campaign.volunteer, style: TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor) ),
                                            Text(campaign.volunteeringDetail, style: TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor)),
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
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '${campaign.currentVolunteers}/${campaign.volunteer}',
                                                style: const TextStyle(
                                                  fontFamily: 'Raleway',
                                                  color: descColor,
                                                  fontSize: 10.0,
                                                ),
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
                            campaign.locationLink != "" ?
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
                                    campaign.locationLink,
                                    style: const TextStyle(fontSize: 12, fontFamily: 'SourceSansPro', fontWeight: FontWeight.normal, color: descColor)
                                ),
                              ],
                            ):
                            Container(),
                            campaign.locationLink != "" ?
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
                                    campaign.address,
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
                                                    campaign.selectedLocation.latitude,
                                                    campaign.selectedLocation.longitude,
                                                  ),
                                                  zoom: 15,
                                                ),
                                                onMapCreated: (controller) {
                                                  setState(() {
                                                    _mapController = controller;
                                                  });
                                                },
                                                markers: campaign.selectedLocation == null
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
                                                    if (_mapController != null && campaign.selectedLocation != null) {
                                                      _mapController!.animateCamera(
                                                        CameraUpdate.newLatLng(
                                                          LatLng(
                                                            campaign.selectedLocation.latitude,
                                                            campaign.selectedLocation.longitude,
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
                            isJoined && campaign.isCompleted == true?
                            Container():
                            isJoined && campaign.isCompleted == false?
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
                                                    "Cancelling campaign...",
                                                    style: TextStyle(fontFamily: 'Raleway'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );

                                        try {
                                          //cancel participation
                                          await cancelCampaign(widget.campaignID, auth.getCurrentUID());

                                        } catch (e) {
                                          // Hide loading dialog and show error dialog
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Error', style: TextStyle(fontFamily: 'Raleway')),
                                                content: Text('An error occurred while cancelling the campaign.', style: TextStyle(fontFamily: 'Raleway')),
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
                                                    "Joining campaign...",
                                                    style: TextStyle(fontFamily: 'Raleway'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );

                                        try {
                                          // Call joinCampaign
                                          await joinCampaign(widget.campaignID, auth.getCurrentUID(), (auth.getUser()?.photoURL).toString(), (auth.getUser()?.displayName).toString());

                                        } catch (e) {
                                          // Hide loading dialog and show error dialog
                                          print(e);
                                          Navigator.of(context).pop();
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Error', style: TextStyle(fontFamily: 'Raleway')),
                                                content: Text('An error occurred while joining the campaign.', style: TextStyle(fontFamily: 'Raleway')),
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

  Future<void> reportCampaign(String campaignId, String userId) async {
    final campaignRef = FirebaseFirestore.instance.collection('campaigns').doc(campaignId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final campaignSnapshot = await transaction.get(campaignRef);
      final campaignData = Campaign.fromFirestore(campaignSnapshot);

      if (campaignData.isCompleted) {
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
        campaignRef,
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
            content: Text('You have reported this campaign, the community admin will further review this activity.', style: TextStyle(fontFamily: 'Raleway')),
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

  Future<void> onClicked(BuildContext context, int item, String userId, String campaignId, String imageUrl,
                         String campaignName, String campaignAddress, String organizerName) async {
    int count = 0;

    switch(item){
      case 0 :
        final uri = Uri.parse(imageUrl);
        final response = await http.get(uri);
        final bytes = response.bodyBytes;
        final temp = await getTemporaryDirectory();
        final path = '${temp.path}/communitycampaigns.jpg';
        File(path).writeAsBytesSync(bytes);

        DynamicLinkProvider().createCampaignLink(campaignId, campaignName, campaignAddress, organizerName).then((value) async {
          await Share.shareFiles([path], text: value, subject: 'Join us in making a positive impact on our community!');
        });
        break;

      case 1 :
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
                        "Reporting campaign...",
                        style: TextStyle(fontFamily: 'Raleway'),
                      ),
                    ],
                  ),
                );
              },
            );

            try {
              // Call reportEvent
              await reportCampaign(campaignId, userId);

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
        Navigator.push(context, MaterialPageRoute(builder: (context) => OrganisationProfilePreview(userId: userId)));
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
          'Are you sure you want to volunteer at this campaign?',
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
          'Are you sure you want to cancel your participation at this campaign?',
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
          'Are you sure you want to report this campaign? You should only report it if there are potential details of illegal activity.',
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