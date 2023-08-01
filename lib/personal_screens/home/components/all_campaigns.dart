import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mycommunity/organisation_screens/campaign/components/search_field.dart';
import 'package:mycommunity/personal_screens/home/components/campaign_detail.dart';
import 'package:mycommunity/personal_screens/home/components/model/campaign.dart';
import 'package:mycommunity/personal_screens/home/components/model/campaign_all.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:intl/intl.dart';

class AllCampaigns extends StatefulWidget {

  @override
  _AllCampaigns createState() => _AllCampaigns();
}

class _AllCampaigns extends State<AllCampaigns> {
  String _email = "", _password = "", organizerName = ""; String userId = "";
  double _radius = 1000;
  List<dynamic> userPreferences = [];
  LocationData? _currentLocation;
  String _searchQuery = '';

  void getOrganizerDetail(String organizerID) async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    await db
        .collection('users_data')
        .doc(organizerID)
        .get()
        .then((value) {
      organizerName = value['username'];
    });
  }

  void fetchUserPreferences() async {
    final userID = FirebaseAuth.instance.currentUser!.uid;
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users_data').doc(userID).get();
      List<dynamic> userPreferences = List<dynamic>.from(userSnapshot['preferences']);

      setState(() {
        // Set the user's preferences to a state variable
        this.userPreferences = userPreferences;
      });
    } catch (e) {
      print('Error retrieving user preferences: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    // stop listening to the animation
    super.dispose();
  }

  void _getCurrentLocation() async {
    final location = Location();
    final currentLocation = await location.getLocation();
    setState(() {
      _currentLocation = currentLocation;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: mainBackColor,
      appBar: AppBar(
        leading: const BackButton(color: kPrimaryColor),
        centerTitle: true,
        title: const Text(
          "Trending Campaigns",
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
            crossAxisAlignment: CrossAxisAlignment.start,
             children: [
             Stack(
             children:[
             Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.topCenter,
                color: Colors.white,
                height: size.height*0.15,
                child: SearchField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
             ),
             Column(
               children: [
                 SizedBox(height: size.height*0.10),
                 Container(
                   alignment: Alignment.center,
                   margin: const EdgeInsets.only(bottom: 10, left:15, right: 15),
                   child: Card(
                     elevation: 4, // Adjust the elevation value as needed
                     shadowColor: Colors.grey.withOpacity(0.4), // Customize the shadow color
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(20),
                       side: const BorderSide(
                         color: Colors.grey,
                         width: 1.0,
                       ),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.center,
                       children: [
                         Slider(
                           value: _radius,
                           min: 100,
                           max: 200000,
                           onChanged: (value) {
                             setState(() {
                               _radius = value;
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
                ],
               )
              ]
             ),
            //Trending individual campaign
             Padding(
                padding: EdgeInsets.only(left: 15,right: 15),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('campaigns')
                      .where('is_completed', isEqualTo: false)
                      .where('date_time_start', isGreaterThan: DateTime.now())
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.active) {
                      return Container(
                        height: size.height*0.5,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(),
                      );
                    }

                    var campaigns = snapshot.data!.docs.map((doc) {
                      final campaign = campaignInfo.fromDoc(doc);
                      campaign.id = doc.id;
                      return campaign;
                    }).toList();

                    if (campaigns.isEmpty) {
                      return
                        Container(
                            height: size.height*0.5,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(10),
                            child: const Center(
                              child: Text('No trending campaign right now, Please stay tune!', style: TextStyle(fontFamily: 'Raleway', fontSize: 13, fontWeight: FontWeight.bold)),
                            )
                        );
                    }

                    // Sort events based on user's preferences
                    List<campaignInfo> sortedCampaigns = [];

                    // Separate events into two lists: user preference events and other events
                    for (int i = 0; i < campaigns.length; i++) {
                      final campaign = campaigns[i];

                      if (userPreferences.contains(campaign.category)) {
                        sortedCampaigns.add(campaign);
                      }
                    }

                    // Add the remaining events (not in user preferences) to the sorted lists
                    for (int i = 0; i < campaigns.length; i++) {
                      final campaign = campaigns[i];

                      if (!userPreferences.contains(campaign.category)) {
                        sortedCampaigns.add(campaign);
                      }
                    }

                    // Create a new list of sorted events that match the search query
                    List<campaignInfo> filteredCampaigns = sortedCampaigns.where((campaign) {
                      final campaignTitle = campaign.title.toLowerCase();
                      final searchQuery = _searchQuery.toLowerCase();
                      return campaignTitle.contains(searchQuery);
                    }).toList();

                    if (filteredCampaigns.isEmpty) {
                      return Container(height: size.height*0.5, alignment: Alignment.center, child:Center(child:Text('No campaigns found for "${_searchQuery}"', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor))));
                    }

                    List<campaignInfo> campaignList = [];

                    try {
                      filteredCampaigns.forEach((campaign) {
                        if (calculateDistance(campaign.selectedLocation.latitude, campaign.selectedLocation.longitude) <= _radius) {
                          double distance = calculateDistance(campaign.selectedLocation.latitude, campaign.selectedLocation.longitude);
                          campaign.distance = distance;
                          campaignList.add(campaign);
                        }
                      });
                    } catch (error) {
                      print('Error fetching activities: $error');
                    }

                    if (campaignList.isEmpty) {
                      return Container(height: size.height*0.5, alignment: Alignment.center, child:Center(child:Text('No campaigns found within the radius of "${_formatRadius(_radius)}" around you!', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor))));
                    }

                    return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        itemCount: campaignList.length,
                        itemBuilder: (context, index) {
                          final campaign = campaignList[index];
                          final campaignID = campaignList[index].id;

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: campaignID)));
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Colors.white,
                                  width: 1.0,
                                ),
                              ),
                              elevation: 3.0,
                              margin: EdgeInsets.all(8.0),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(8.0),
                                leading: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20.0),
                                    child: Image.network(
                                      campaign.imageUrl,
                                      width: 100.0,
                                      height: 125.0,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  campaign.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: kPrimaryColor, fontFamily: 'Raleway', fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8.0),
                                    Text(
                                      campaign.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10, color: mainTextColor, fontFamily: 'SourceSansPro', fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      campaign.category,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10, color: mainTextColor, fontFamily: 'SourceSansPro', fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Distance: ${_formatRadius(campaign.distance)}",
                                      style: TextStyle(fontSize: 10, color: mainTextColor, fontFamily: 'SourceSansPro', fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(
                                    child:TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(MaterialPageRoute(builder: (context) =>  CampaignDetailScreen(campaignID: campaignID)));
                                      },
                                      child: const Text(
                                        'See detail >',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: kPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins'// Customize the text color
                                        ),
                                      ),
                                    ),
                                   )
                                  ],
                                )
                              ),
                            ),
                          );
                        },
                      );
                  },
              ),
             )
            ]
         )
        )
      ),
    );
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

}