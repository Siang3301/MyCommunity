import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mycommunity/organisation_screens/campaign/components/edit_campaign.dart';
import 'package:mycommunity/organisation_screens/campaign/model/campaign.dart';
import 'package:mycommunity/organisation_screens/profile/organisation_preview.dart';
import 'package:mycommunity/personal_screens/activity/components/participant_list.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/services/dynamic_link.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:intl/intl.dart';
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
  String organizerContact = "", organizerName = "", imageUrl = "", campaignName = "", campaignAddress = "";
  bool _isDraggingMap = false;

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

      if (doc.exists) {
        Campaign campaign = Campaign.fromFirestore(doc);
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

  Future<void> markActivityCompleted(String campaignID, String userId) async {
    final campaignRef = FirebaseFirestore.instance.collection('campaigns').doc(campaignID);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final campaignSnapshot = await transaction.get(campaignRef);
      final campaingData = Campaign.fromFirestore(campaignSnapshot);

      if (campaingData.isCompleted) {
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

      if (DateTime.now().isBefore(campaingData.dateTimeEnd)) {
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
        campaignRef,
        {
          'is_completed': true,
          'complete_time': DateTime.now()
        },
      );

      //Add award to the user.
      addAward(campaingData, userId);

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
                    '/home_2', (route) => false,
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

  void addAward(Campaign campaignData, String organizerId) async {
    try {
      // Calculate volunteer time
      DateTime startDateTime = campaignData.dateTimeStart;
      DateTime endDateTime = campaignData.dateTimeEnd;
      int volunteersJoined = int.parse(campaignData.currentVolunteers);
      int volunteersRequired = int.parse(campaignData.volunteer);
      List<dynamic> joinedUserIds = campaignData.joinedUserIds;
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

        // Update total participated campaigns
        int totalParticipatedCampaigns = userData['total_participated_campaigns'] ?? 0;
        totalParticipatedCampaigns++;

        // Update the user document with the new values
        await userRef.update({
          'total_volunteer_hours': userTotalVolunteerHours,
          'total_volunteer_minutes': userTotalVolunteerMinutes,
          'total_participated_campaigns': totalParticipatedCampaigns,
        });
      }

      // Update organizer's total organized event number
      DocumentSnapshot orgSnapshot = await orgRef.get();
      Map<String, dynamic> userData = orgSnapshot.data() as Map<String, dynamic>;
      int totalCampaignOrganized = userData['total_campaign_organized'] ?? 0;
      int totalVolunteerAccumulated = userData['total_volunteer_accumulated'] ?? 0;
      int totalVolunteerRequired = userData['total_volunteer_required'] ?? 0;
      totalCampaignOrganized++;
      totalVolunteerAccumulated += volunteersJoined;
      totalVolunteerRequired += volunteersRequired;

      await orgRef.update({
        'total_campaign_organized': totalCampaignOrganized,
        'total_volunteer_accumulated': totalVolunteerAccumulated,
        'total_volunteer_required': totalVolunteerRequired
      });

      print("Awarding process done! cheers!");
    } catch (error) {
      print('Error adding reward: $error');
    }
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
                  onSelected: (item) => onClicked(context, item, auth.getUser()!.uid.toString(), widget.campaignID, imageUrl, campaignName, campaignAddress, organizerName),
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
                         onPressed: ()  {
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
                                           "Completing campaign...",
                                           style: TextStyle(fontFamily: 'Raleway'),
                                         ),
                                       ],
                                     ),
                                   );
                                 },
                               );

                               try {
                                 // Call joinEvent and addUserActivity
                                 await markActivityCompleted(widget.campaignID, auth.getCurrentUID());

                               } catch (e) {
                                 // Hide loading dialog and show error dialog
                                 Navigator.of(context).pop();
                                 showDialog(
                                   context: context,
                                   builder: (BuildContext context) {
                                     return AlertDialog(
                                       title: Text('Error', style: TextStyle(fontFamily: 'Raleway')),
                                       content: Text('An error occurred while completing the campaign.', style: TextStyle(fontFamily: 'Raleway')),
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
                             backgroundColor: orgMainColor.withOpacity(0.9),
                         ),
                         child: const Text(
                           "COMPLETE", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                         ),
                       ),
                     ),
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
                                          Text(
                                            '${campaign.currentVolunteers}/${campaign.volunteer}',
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                campaign.isCompleted == false ?
                                Container(
                                  width: size.width * 0.40,
                                  height: size.height * 0.05,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child:ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditCampaign(campaignID: widget.campaignID)));// Implement edit campaign function
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: orgMainColor
                                    ),
                                    child: const Text(
                                      "EDIT CAMPAIGN", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
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
                                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => ParticipantList(activityId: widget.campaignID, activityType: 'campaigns')));// Implement edit campaign function
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: orgMainColor
                                    ),
                                    child: const Text(
                                      "DETAIL", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => OrganisationProfilePreview(userId: userId)));
      break;
  }
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
          'Are you sure you want to complete this campaign? All the participants will be awarded after you completely ended the campaign.',
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
              'Yes, the campaign is completed!',
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