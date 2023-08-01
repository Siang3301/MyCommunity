import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/organisation_screens/campaign/components/campaign_detail.dart';
import 'package:mycommunity/organisation_screens/campaign/components/search_field.dart';
import 'package:mycommunity/organisation_screens/profile/components/account_management.dart';
import 'package:mycommunity/organisation_screens/profile/organisation_preview.dart';
import 'package:mycommunity/organisation_screens/statistics/components/geofence_statistics.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/organisation_screens/statistics/components/background.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:intl/intl.dart';

String formatDateTime(DateTime dateTime) {
  final formatter = DateFormat('dd MMM yyyy h:mm a');
  String formattedDateTime = formatter.format(dateTime);
  return formattedDateTime;
}

class ArchiveSpace extends StatefulWidget{
  const ArchiveSpace({Key? key}) : super(key: key);

  @override
  _ArchiveSpace createState() => _ArchiveSpace();
}

class _ArchiveSpace extends State<ArchiveSpace>
    with TickerProviderStateMixin{
  final _formKey = GlobalKey<FormState>();
  TabController? _tabController;
  int selectedTabIndex = 0;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _categories = ["Aid & Community", "Animal Welfare", "Art & Culture", "Children & Youth", "Education & Lectures",
    "Disabilities", "Environment", "Food & Hunger", "Health & Medical", "Technology", "Skill-based Volunteering",  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController!.removeListener(_handleTabSelection);
    _tabController!.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      selectedTabIndex = _tabController!.index;
    });
  }

  void _deleteCampaign(String campaignId, String userId) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        title: Text(
          'Confirm',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete this campaign?',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontSize: 14,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text(
              'Yes',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        FirebaseFirestore.instance.collection('users_data').doc(userId).collection('archived_campaign').doc(campaignId).delete().then((_) {
          // showDialog(
          //   context: context,
          //   builder: (BuildContext context) {
          //     return AlertDialog(
          //       title: Text('Success', style: TextStyle(fontFamily: 'Raleway')),
          //       content: Text('You have permanently removed the campaign!', style: TextStyle(fontFamily: 'Raleway')),
          //       actions: [
          //         TextButton(
          //           child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
          //           onPressed: () {
          //             Navigator.of(context).pop();
          //           },
          //         ),
          //       ],
          //     );
          //   },
          // );
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Campaign deleted successfully', style: TextStyle(fontFamily: 'Raleway')),
          ));
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('An error occurred while deleting the campaign: $error'),
            backgroundColor: Colors.red,
          ));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        backgroundColor: mainBackColor,
        appBar : AppBar(
          leading: const BackButton(color: kPrimaryColor),
          centerTitle: false,
          title:  const Text("Archive Space", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
          backgroundColor: Colors.white,
          bottomOpacity: 0.0,
          elevation: 0.0,
        ),
        body: Form(
            key: _formKey,
            child: Background(
              child: SingleChildScrollView(
                  child: SafeArea(
                    child: Column(
                      children: <Widget>[
                        Container(
                            padding: EdgeInsets.only(left: 10, right: 10),
                            alignment: Alignment.center,
                            height: size.height*0.10,
                            child: SearchField(
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            )
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
                          child: Container(
                              child: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('users_data').doc(auth.getCurrentUID()).collection('archived_campaign')
                                    .where('organizerID', isEqualTo: auth.getCurrentUID())
                                    .where('date_time_end', isLessThan: Timestamp.now())
                                    .where('is_completed', isEqualTo: true)
                                    .where('is_archived', isEqualTo: true)
                                    .orderBy('date_time_end', descending: true)
                                    .snapshots(),
                                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  }
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return SizedBox(height: size.height*0.60, child:Center(child: CircularProgressIndicator()));
                                  }
                                  if (snapshot.data!.docs.isEmpty) {
                                    return SizedBox(height: size.height*0.60, child:Center(child:Text('You do not have any archived campaign.', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor))));
                                  }

                                  // Filter campaigns based on search query
                                  List<QueryDocumentSnapshot> filteredDocs = [];
                                  snapshot.data!.docs.forEach((doc) {
                                    bool matchesQuery = false;
                                    if (doc['title'].toLowerCase().contains(_searchQuery.toLowerCase())) {
                                      matchesQuery = true;
                                    } else if (doc['description'].toLowerCase().contains(_searchQuery.toLowerCase())) {
                                      matchesQuery = true;
                                    } else if (doc['category'].toLowerCase().contains(_searchQuery.toLowerCase())) {
                                      matchesQuery = true;
                                    }
                                    if (matchesQuery) {
                                      filteredDocs.add(doc);
                                    }
                                  });

                                  if (filteredDocs.isEmpty) {
                                    return Center(child:Text('No campaigns found for "${_searchQuery}"', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                  }

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: filteredDocs.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      DocumentSnapshot document = filteredDocs[index];
                                      DateTime dateStart = document['date_time_start'].toDate();
                                      DateTime dateEnd = document['date_time_end'].toDate();
                                      DateTime completeTime = document['complete_time'].toDate();
                                      String formattedTime = DateFormat('h:mm a').format(dateStart);
                                      String formattedDateStart = DateFormat('dd MMM yy').format(dateStart);
                                      String formattedDateEnd = DateFormat('dd MMM yy').format(dateEnd);
                                      String formattedSingleDate = DateFormat('dd MMM yy').format(dateEnd);

                                      return Column(
                                           children: [
                                                Card(
                                                  elevation: 5,
                                                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                                  color: Colors.white,
                                                  child: Column(
                                                    children: [
                                                      IntrinsicHeight(
                                                      child:Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => GeofencingStatistics(campaignId: document.id)));
                                                            },
                                                            child: Text('Campaign Statistics', style: TextStyle(fontFamily: 'Raleway', color: orgMainColor, fontSize: 14)),
                                                          ),
                                                          const VerticalDivider(
                                                            color: Colors.blueGrey, // Customize the color of the vertical line
                                                            thickness: 0.3, // Customize the thickness of the vertical line
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: document.id)));
                                                            },
                                                            child: Text('Campaign Details', style: TextStyle(fontFamily: 'Raleway', color: orgMainColor, fontSize: 14)),
                                                          ),
                                                        ],
                                                       )
                                                      ),
                                                      const Divider(color: Colors.blueGrey, thickness: 0.3, height:0),
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        children: [
                                                          Padding(
                                                              padding: const EdgeInsets.all(15.0),
                                                                child: CircleAvatar(
                                                                  radius: 30,
                                                                  backgroundImage: CachedNetworkImageProvider(document['image_url']),
                                                                ),
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Container(
                                                                  padding: const EdgeInsets.only(top: 15, right: 10),
                                                                  margin: EdgeInsets.only(bottom: 10),
                                                                  child: Text(
                                                                    document['title'],
                                                                    style: const TextStyle(
                                                                      fontSize: 12.0,
                                                                      color: kPrimaryColor,
                                                                      overflow: TextOverflow.ellipsis,
                                                                      fontFamily: 'Raleway',
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                    maxLines: 2,
                                                                  ),
                                                                ),
                                                                Container(
                                                                  padding: const EdgeInsets.only(right: 10),
                                                                  margin: EdgeInsets.only(bottom: 20),
                                                                  child: Text(
                                                                    document['description'],
                                                                    style: const TextStyle(
                                                                        fontSize: 10.0,
                                                                        overflow: TextOverflow.ellipsis,
                                                                        color: descColor,
                                                                        fontFamily: 'SourceSansPro'
                                                                    ),
                                                                    maxLines: 2,
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding: EdgeInsets.only(right: 5),
                                                            child:Column(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                  children: [
                                                                    Icon(Icons.calendar_today, color: descColor),
                                                                    SizedBox(width: 5),
                                                                    Text(
                                                                      dateEnd.difference(dateStart).inDays > 0
                                                                          ? formattedDateStart + ' -\n' + formattedDateEnd
                                                                          : formattedSingleDate,
                                                                      textAlign: TextAlign.left,
                                                                      style: const TextStyle(
                                                                        fontFamily: 'Raleway',
                                                                        color: kPrimaryColor,
                                                                        fontSize: 10.0,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                  children: [
                                                                    Icon(Icons.access_time, color: descColor),
                                                                    SizedBox(width: 5),
                                                                    Text(
                                                                      formattedTime,
                                                                      style: const TextStyle(
                                                                        fontFamily: 'Raleway',
                                                                        color: kPrimaryColor,
                                                                        fontSize: 10.0,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                                  children: [
                                                                    Icon(Icons.people, color: descColor),
                                                                    SizedBox(width: 5),
                                                                    Text(
                                                                      '${document['currentVolunteers']}/${document['maxVolunteers']}',
                                                                      style: const TextStyle(
                                                                        fontFamily: 'Raleway',
                                                                        color: kPrimaryColor,
                                                                        fontSize: 10.0,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              IconButton(
                                                                icon: const Icon(Icons.delete, color: orgMainColor),
                                                                onPressed: () {
                                                                  _deleteCampaign(document.id, auth.getCurrentUID());
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      Padding(
                                                        padding: EdgeInsets.all(5),
                                                        child: Text(
                                                          'Completed on: ${formatDateTime(completeTime)}',
                                                          style: const TextStyle(
                                                            fontStyle: FontStyle.italic,
                                                            fontFamily: 'Raleway',
                                                            color: Colors.green,
                                                            fontSize: 14
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  )
                                                ),
                                                const SizedBox(height: 5),
                                              ]
                                          );
                                    },
                                  );
                                },
                              )
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
}





