import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as lc;
import 'package:mycommunity/personal_screens/home/components/all_campaigns.dart';
import 'package:mycommunity/personal_screens/home/components/all_events.dart';
import 'package:mycommunity/personal_screens/home/components/big_map.dart';
import 'package:mycommunity/personal_screens/home/components/campaign_detail.dart';
import 'package:mycommunity/personal_screens/home/components/event_detail.dart';
import 'package:mycommunity/personal_screens/home/components/map_screen.dart';
import 'package:mycommunity/personal_screens/home/components/model/campaign.dart';
import 'package:mycommunity/personal_screens/home/components/model/event.dart';
import 'package:mycommunity/personal_screens/home/components/notification_history.dart';
import 'package:mycommunity/personal_screens/profile/components/account_management.dart';
import 'package:mycommunity/personal_screens/profile/profile_preview.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/personal_screens/home/components/background.dart';
import 'package:mycommunity/personal_screens/home/components/search_field.dart';
import 'package:mycommunity/personal_screens/home/components/side_menu.dart';
import 'package:mycommunity/services/dynamic_link.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

int generateRandomNumber() {
  final random = Random();
  final number = random.nextInt(99999999 - 10000000 + 1) + 10000000;
  return number;
}

class PersonalHomeBody extends StatefulWidget{
  const PersonalHomeBody({Key? key}) : super(key: key);

  @override
  _PersonalHomeBody createState() => _PersonalHomeBody();
}

class _PersonalHomeBody extends State<PersonalHomeBody> {
  final _formKey = GlobalKey<FormState>();
  String _email = "", _password = "", organizerName = ""; String userId = "", _currentCity = "City", _currentState = "State";
  double _radius = 1000;
  lc.LocationData? _currentLocation;
  List<dynamic> userPreferences = [];
  bool isLocationLoaded = false;
  bool isPreferencesLoaded = false;
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
        isPreferencesLoaded = true;
      });
    } catch (e) {
      print('Error retrieving user preferences: $e');
    }
  }

  void _onValueChanged(double radius) {
    setState(() {
      _radius = radius;
    });
  }

  void _getCurrentLocation() async {
    final location = lc.Location();
    final currentLocation = await location.getLocation();

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        currentLocation.latitude!,
        currentLocation.longitude!,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String city = placemark.locality ?? '';
        String state = placemark.administrativeArea ?? '';

        setState(() {
          _currentLocation = currentLocation;
          _currentCity = city;
          _currentState = state;
          isLocationLoaded = true;
        });
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    fetchUserPreferences();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        drawer: NavDrawer(userId: auth.getCurrentUID()),
        backgroundColor: mainBackColor,
        appBar : AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu_rounded, color: kPrimaryColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        backgroundColor: Colors.white,
        bottomOpacity: 0.0,
        elevation: 0.0,
        centerTitle: true,
        title: const Text("MyCommunity", style: TextStyle(fontFamily: 'Raleway', fontSize: 23, color: kPrimaryColor)),
        actions: <Widget>[
          InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalProfilePreview(userId: auth.getCurrentUID())));
              },
              child:
              auth.getUser()?.photoURL == null || auth.getUser()?.photoURL == "null" || auth.getUser()?.photoURL == ""
                  ? Icon(Icons.account_circle_rounded, color: kPrimaryColor, size: 26)
                  : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryColor, width: 1),
                ),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(auth.getUser()?.photoURL as String),
                  radius: 12,
                ),
              )
          ),
          IconButton(
            icon: const Icon(Icons.circle_notifications_rounded, color: kPrimaryColor, size: 26),
            highlightColor: kPrimaryColor,
            color: Colors.white,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationHistory(userId: auth.getCurrentUID())));
            },
          ),
          ],
      ),
      body: Form(
        key: _formKey,
        child: Background(
          child: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Stack(
                    children: [
                      Container(
                        color: Colors.white,
                        height: size.height*0.15,
                        width: size.width,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: size.width*0.70,
                                  child: Text(
                                    "Hi, ${auth.getUser()?.displayName}", textAlign: TextAlign.start, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style : const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: mainTextColor, fontFamily: "Raleway"
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _currentState, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontFamily: 'Poppins', color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12,  fontStyle: FontStyle.italic),
                                  )
                                )
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                SizedBox(
                                  width: size.width*0.50,
                                  child: Text(
                                      "Let's explore community activities around your neighborhood area!",  textAlign: TextAlign.start, maxLines: 2,
                                      style : const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mainTextColor, fontFamily: "Raleway"
                                      )
                                  )
                                ),
                                Expanded(
                                    child: Text(
                                      _currentCity, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontFamily: 'Poppins', color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    )
                                )
                              ],
                            )
                          ]
                        ),
                      ),
                      Container(
                          padding: EdgeInsets.only(left: 10, right: 10),
                          margin: EdgeInsets.only(top: size.height*0.075),
                          alignment: Alignment.center,
                          height: size.height*0.15,
                          child: SearchField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          )
                      ),
                      Container(
                        margin: EdgeInsets.only(top: size.height*0.19),
                        padding: const EdgeInsets.only(left: 25, right: 20),
                        child:Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              "Discover community service around you", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold,  fontSize: 12, color: mainTextColor),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward, color: kPrimaryColor, size: 22),
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => BigMapScreen()));
                              },
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.only(top:5, left: 20, right: 20),
                    child: MapScreen(
                       onValueChanged: _onValueChanged
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 25, top: 15),
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          "Recommended Trending Campaigns", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 12, color: mainTextColor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward, color: kPrimaryColor, size: 22),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => AllCampaigns()));
                          },
                        )
                      ],
                    ),
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
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      var campaigns = snapshot.data!.docs.map((doc) {
                        final campaign = campaignInfo.fromDoc(doc);
                        campaign.id = doc.id;
                        return campaign;
                      }).toList();

                      if(isLocationLoaded) {
                        if (campaigns.isEmpty) {
                          return
                          Container(
                            height: 100,
                            padding: const EdgeInsets.all(10),
                            child: const Center(
                              child: Text('No trending campaign right now. \nPlease stay tune!', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Raleway', fontSize: 13, fontWeight: FontWeight.bold)),
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
                          final event = campaigns[i];

                          if (!userPreferences.contains(event.category)) {
                            sortedCampaigns.add(event);
                          }
                        }

                        // Create a new list of sorted events that match the search query
                        List<campaignInfo> filteredCampaigns = sortedCampaigns
                            .where((campaign) {
                          final campaignTitle = campaign.title.toLowerCase();
                          final searchQuery = _searchQuery.toLowerCase();
                          return campaignTitle.contains(searchQuery);
                        }).toList();

                        if (filteredCampaigns.isEmpty) {
                          return Container(height: size.height * 0.1,
                              child: Center(child: Text(
                                  'No campaigns found for "${_searchQuery}"', textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'SourceSansPro',
                                      fontSize: 13,
                                      color: mainTextColor))));
                        }

                        List<campaignInfo> campaignList = [];

                        try {
                          filteredCampaigns.forEach((campaign) {
                            if (calculateDistance(
                                campaign.selectedLocation.latitude,
                                campaign.selectedLocation.longitude) <=
                                _radius) {
                              double distance = calculateDistance(
                                  campaign.selectedLocation.latitude,
                                  campaign.selectedLocation.longitude);
                              campaign.distance = distance;
                              campaignList.add(campaign);
                            }
                          });
                        } catch (error) {
                          print('Error fetching activities: $error');
                        }

                        if (campaignList.isEmpty) {
                          return Container(height: size.height * 0.1,
                              child: Center(child: Text(
                                  'No campaigns found within the radius of "${_formatRadius(
                                      _radius)}" around you!', textAlign: TextAlign.center, style: TextStyle(
                                  fontFamily: 'SourceSansPro',
                                  fontSize: 13,
                                  color: mainTextColor))));
                        }

                        return Container(
                          height: 200.0,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: campaignList.length > 5
                                ? 5
                                : campaignList.length,
                            itemBuilder: (context, index) {
                              final campaign = campaignList[index];
                              final campaignID = campaignList[index].id;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) =>
                                          CampaignDetailScreen(
                                              campaignID: campaignID)));
                                },
                                child: Container(
                                  width: 175.0,
                                  height: 100.0,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 1.0,
                                      )
                                  ),
                                  margin: EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20.0),
                                          topRight: Radius.circular(20.0),
                                        ),
                                        child: Image.network(
                                          campaign.imageUrl,
                                          width: 175.0,
                                          height: 100.0,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            Text(
                                              campaign.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 12,
                                                  color: kPrimaryColor,
                                                  fontFamily: 'Raleway',
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: 8.0),
                                            Text(
                                              campaign.category,
                                              style: TextStyle(fontSize: 10,
                                                  color: mainTextColor,
                                                  fontFamily: 'SourceSansPro',
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          "Distance: ${_formatRadius(
                                              campaign.distance)}",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(fontSize: 10,
                                              color: mainTextColor,
                                              fontFamily: 'SourceSansPro',
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }else{
                        _getCurrentLocation();
                        return Center(child:CircularProgressIndicator());
                      }
                    },
                   )
                  ),
                  Container(
                    padding: const EdgeInsets.only(left: 25),
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Text(
                          "Recommended Individual Events", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 12, color: mainTextColor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward, color: kPrimaryColor, size: 22),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => AllEvents()));
                          },
                        )
                      ],
                    ),
                  ),
                  //Trending individual event
                  Padding(
                    padding: EdgeInsets.only(left: 15, right: 15),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('events')
                          .where('is_completed', isEqualTo: false)
                          .where('date_time_start', isGreaterThan: DateTime.now())
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.active) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        var events = snapshot.data!.docs.map((doc) {
                          final event = eventInfo.fromDoc(doc);
                          event.id = doc.id;
                          return event;
                        }).toList();

                        if(isLocationLoaded) {
                          if (events.isEmpty) {
                            return Container(
                              height: 100,
                              padding: const EdgeInsets.all(10),
                              child: const Center(
                                child: Text('No trending individual events right now.\nPlease stay tuned!', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Raleway', fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            );
                          }
                          // Sort events based on user's preferences
                          List<eventInfo> sortedEvents = [];

                          // Separate events into two lists: user preference events and other events
                          for (int i = 0; i < events.length; i++) {
                            final event = events[i];

                            if (userPreferences.contains(event.category)) {
                              sortedEvents.add(event);
                            }
                          }

                          // Add the remaining events (not in user preferences) to the sorted lists
                          for (int i = 0; i < events.length; i++) {
                            final event = events[i];

                            if (!userPreferences.contains(event.category)) {
                              sortedEvents.add(event);
                            }
                          }

                          // Create a new list of sorted events that match the search query
                          List<eventInfo> filteredEvents = sortedEvents.where((
                              event) {
                            final eventTitle = event.title.toLowerCase();
                            final searchQuery = _searchQuery.toLowerCase();
                            return eventTitle.contains(searchQuery);
                          }).toList();

                          if (filteredEvents.isEmpty) {
                            return Container(height: size.height * 0.1,
                                child: Center(child: Text(
                                    'No events found for "${_searchQuery}"', textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: 'SourceSansPro',
                                        fontSize: 13,
                                        color: mainTextColor))));
                          }

                          List<eventInfo> eventList = [];

                          try {
                            filteredEvents.forEach((event) {
                              if (calculateDistance(
                                  event.selectedLocation.latitude,
                                  event.selectedLocation.longitude) <=
                                  _radius) {
                                double distance = calculateDistance(
                                    event.selectedLocation.latitude,
                                    event.selectedLocation.longitude);
                                event.distance = distance;
                                eventList.add(event);
                              }
                            });
                          } catch (error) {
                            print('Error fetching activities: $error');
                          }

                          if (eventList.isEmpty) {
                            return Container(height: size.height * 0.1,
                                child: Center(child: Text(
                                    'No events found within the radius of "${_formatRadius(
                                        _radius)}" around you!', textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: 'SourceSansPro',
                                        fontSize: 13,
                                        color: mainTextColor))));
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: filteredEvents.length > 10
                                ? 10
                                : filteredEvents.length,
                            itemBuilder: (context, index) {
                              final event = filteredEvents[index];
                              final eventId = filteredEvents[index].id;

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance.collection(
                                    'users_data').doc(event.organizerID).get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState !=
                                      ConnectionState.done ||
                                      !snapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }

                                  final organizerName = snapshot
                                      .data!['username'] ?? 'Community User';

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  EventDetailScreen(
                                                      eventID: eventId)));
                                    },
                                    child: Container(
                                      width: size.width * 0.85,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: Offset(0,
                                                2), // changes position of shadow
                                          ),
                                        ],
                                      ),
                                      margin: EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Row(
                                                  children: [
                                                    SizedBox(
                                                      width: size.width*0.5,
                                                      child: Text(
                                                        event.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            color: kPrimaryColor,
                                                            fontFamily: 'Raleway',
                                                            fontWeight: FontWeight
                                                                .bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 3.0),
                                                Row(
                                                  children: [
                                                    const Icon(Icons
                                                        .person_rounded,
                                                        color: mainTextColor),
                                                    const SizedBox(width: 2.0),
                                                    event.organizerID == auth
                                                        .getCurrentUID()
                                                        ? SizedBox(
                                                      width: size.width*0.45,
                                                      child: const Text(
                                                      "My own event",
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: kPrimaryColor,
                                                          fontFamily: 'SourceSansPro',
                                                          fontWeight: FontWeight
                                                              .bold),
                                                    ))
                                                        : SizedBox(
                                                      width: size.width*0.45,
                                                      child: Text(
                                                      organizerName,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color: mainTextColor,
                                                          fontFamily: 'SourceSansPro',
                                                          fontWeight: FontWeight
                                                              .bold),
                                                      )
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  "Distance: ${_formatRadius(
                                                      event.distance)}",
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(fontSize: 10,
                                                      color: mainTextColor,
                                                      fontFamily: 'SourceSansPro',
                                                      fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              Container(
                                                  padding: EdgeInsets.all(8.0),
                                                  width: size.width*0.3,
                                                  child: Text(
                                                    "(${event
                                                        .volunteers} volunteers needed)",
                                                    textAlign: TextAlign.end,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontSize: 10,
                                                        color: mainTextColor,
                                                        fontFamily: 'SourceSansPro',
                                                        fontWeight: FontWeight
                                                            .bold),
                                                  )
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }else{
                          _getCurrentLocation();
                          return Center(child:CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                ],
              ),
            )
          ),
        )
     )
    );
  }

  List<eventInfo> sortEventsByPreference(List<eventInfo> events, List<dynamic> userPreferences) {
    final List<eventInfo> sortedEvents = List<eventInfo>.from(events);
    final List<eventInfo> userPreferenceEvents = [];
    final List<eventInfo> otherEvents = [];

    for (final event in sortedEvents) {
      if (userPreferences.contains(event.category)) {
        userPreferenceEvents.add(event);
      } else {
        otherEvents.add(event);
      }
    }

    sortedEvents.clear();
    sortedEvents.addAll(userPreferenceEvents);
    sortedEvents.addAll(otherEvents);

    return sortedEvents;
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

class EventData {
  final List<eventInfo> events;
  final List<String> eventIds;

  EventData(this.events, this.eventIds);
}






