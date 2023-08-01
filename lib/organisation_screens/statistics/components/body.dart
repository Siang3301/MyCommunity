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


class OrganisationCampaignStatisticsBody extends StatefulWidget{
  const OrganisationCampaignStatisticsBody({Key? key}) : super(key: key);

  @override
  _OrganisationCampaignStatisticsBody createState() => _OrganisationCampaignStatisticsBody();
}

class _OrganisationCampaignStatisticsBody extends State<OrganisationCampaignStatisticsBody>
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        backgroundColor: mainBackColor,
        appBar : AppBar(
          centerTitle: false,
          title:  const Text("Campaign Statistics", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
         backgroundColor: Colors.white,
         bottomOpacity: 0.0,
         elevation: 0.0,
        actions: <Widget>[
          InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => OrganisationProfilePreview(userId: auth.getCurrentUID())));
              },
              child:
              auth.getUser()?.photoURL == null || auth.getUser()?.photoURL == "null" || auth.getUser()?.photoURL == ""
                  ? Container(margin: const EdgeInsets.only(right: 15), child: const Icon(Icons.account_circle_rounded, color: kPrimaryColor, size: 26))                  : Container(
                margin: const EdgeInsets.only(right: 15),
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
          ],
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
                    Container(
                        height: size.height*0.7,
                        padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              indicatorColor: kPrimaryColor,
                              labelColor: kPrimaryColor,
                              unselectedLabelColor: Colors.grey,
                              indicator: BoxDecoration(),
                              indicatorWeight: 0,
                              tabs: [
                                Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: _tabController?.index == 0 ? orgMainColor : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _tabController?.index == 0 ? Colors.white : orgMainColor)
                                  ),
                                  child: Tab(
                                    child: Text(
                                      'Current Campaign',
                                      style: TextStyle(
                                        fontSize: 13, fontFamily: "Raleway",
                                        color: _tabController?.index == 0 ? Colors.white : orgMainColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: _tabController?.index == 1 ? orgMainColor : Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _tabController?.index == 1 ? Colors.white : orgMainColor)
                                  ),
                                  child: Tab(
                                    child: Text(
                                      'Past Campaign',
                                      style: TextStyle(
                                        fontSize: 13, fontFamily: "Raleway",
                                        color: _tabController?.index == 1 ? Colors.white : orgMainColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Flexible(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Current Campaign Tab
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                        child: StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance.collection('campaigns')
                                              .where('organizerID', isEqualTo: auth.getCurrentUID())
                                              .where('is_completed', isEqualTo: false)
                                              .orderBy('date_time_start')
                                              .snapshots(),
                                          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                            if (snapshot.hasError) {
                                              return Text('Error: ${snapshot.error}');
                                            }
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(child: CircularProgressIndicator());
                                            }
                                            if (snapshot.data!.docs.isEmpty) {
                                              return const Center(child:Text('You currently do not organize any campaign.', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
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
                                                String formattedTime = DateFormat('h:mm a').format(dateStart);
                                                String formattedDateStart = DateFormat('dd MMM yy').format(dateStart);
                                                String formattedDateEnd = DateFormat('dd MMM yy').format(dateEnd);
                                                String formattedSingleDate = DateFormat('dd MMM yy').format(dateEnd);

                                                return GestureDetector(
                                                  onTap: (){
                                                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => GeofencingStatistics(campaignId: document.id)));
                                                  },
                                                  child:Column(
                                                    children: [
                                                      Card(
                                                        elevation: 5,
                                                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                                        color: Colors.white,
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Padding(
                                                                padding: const EdgeInsets.all(15.0),
                                                                child: GestureDetector(
                                                                  onTap: (){
                                                                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => GeofencingStatistics(campaignId: document.id)));
                                                                  },
                                                                  child: CircleAvatar(
                                                                    radius: 30,
                                                                    backgroundImage: CachedNetworkImageProvider(document['image_url']),
                                                                  ),
                                                                )
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
                                                              padding: EdgeInsets.only(right:15),
                                                            child: Column(
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
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                    ]
                                                  )
                                                );
                                              },
                                            );
                                          },
                                        )
                                    ),
                                  ),
                                  // Past Campaign Tab
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                        child: StreamBuilder<QuerySnapshot>(
                                          stream: FirebaseFirestore.instance.collection('campaigns')
                                              .where('organizerID', isEqualTo: auth.getCurrentUID())
                                              .where('date_time_end', isLessThan: Timestamp.now())
                                              .where('is_completed', isEqualTo: true)
                                              .where('is_archived', isEqualTo: false)
                                              .orderBy('date_time_end', descending: true)
                                              .snapshots(),
                                          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                                            if (snapshot.hasError) {
                                              return Text('Error: ${snapshot.error}');
                                            }
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Center(child: CircularProgressIndicator());
                                            }
                                            if (snapshot.data!.docs.isEmpty) {
                                              return const Center(child:Text('You currently have no past organized campaign.', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
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
                                                String formattedTime = DateFormat('h:mm a').format(dateStart);
                                                String formattedDateStart = DateFormat('dd MMM yy').format(dateStart);
                                                String formattedDateEnd = DateFormat('dd MMM yy').format(dateEnd);
                                                String formattedSingleDate = DateFormat('dd MMM yy').format(dateEnd);

                                                return GestureDetector(
                                                  onTap: (){
                                                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => GeofencingStatistics(campaignId: document.id)));
                                                  },
                                                  child:Stack(
                                                    children: [
                                                      Card(
                                                        elevation: 5,
                                                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                                        color: Colors.white,
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Padding(
                                                                padding: const EdgeInsets.all(15.0),
                                                                child: GestureDetector(
                                                                  onTap: (){
                                                                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => GeofencingStatistics(campaignId: document.id)));
                                                                  },
                                                                  child: CircleAvatar(
                                                                    radius: 30,
                                                                    backgroundImage: CachedNetworkImageProvider(document['image_url']),
                                                                  ),
                                                                )
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
                                                              padding: EdgeInsets.only(right: 15),
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
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Positioned(
                                                        top: -5,
                                                        left: -3,
                                                        child: document['is_completed'] ? ImageIcon(
                                                          AssetImage('assets/icons/campaign_complete.png'),
                                                          color: Colors.green,
                                                          size: 50,
                                                        ) : Container(),
                                                      ),
                                                    ]
                                                  )
                                                );
                                              },
                                            );
                                          },
                                        )
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                    )
                  ],
                ),
              )
          ),
        )
     )
    );
  }
}





