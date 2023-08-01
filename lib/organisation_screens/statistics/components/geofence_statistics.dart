import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mycommunity/organisation_screens/statistics/components/bar_chart.dart';
import 'package:mycommunity/organisation_screens/statistics/components/pie_chart.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:mycommunity/organisation_screens/statistics/model/campaign.dart';
import 'package:intl/intl.dart';


class GeofencingStatistics extends StatefulWidget{
  final String campaignId;
  const GeofencingStatistics({Key? key, required this.campaignId}) : super(key: key);

  @override
  _GeofencingStatistics createState() => _GeofencingStatistics();
}

class _GeofencingStatistics extends State<GeofencingStatistics>
    with TickerProviderStateMixin{

  TabController? _tabController;
  int selectedTabIndex = 0;

  Stream<DocumentSnapshot<Map<String, dynamic>>> getCampaignDataStream() {
    return FirebaseFirestore.instance.collection('campaigns').doc(widget.campaignId).snapshots();
  }

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
      selectedTabIndex = _tabController!.index;
  }

   int getTotalPromotedCount(List<dynamic> usersPromotedList) {
    int totalCount = 0;
    for (var entry in usersPromotedList) {
      int count = entry['count'];
      totalCount += count;
    }
    return totalCount;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: secBackColor,
      appBar: AppBar(
        leading: const BackButton(color: kPrimaryColor),
        centerTitle: true,
        title: const Text(
          "Geofence Statistics",
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
      body: SingleChildScrollView(
      child:StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: getCampaignDataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: size.height*0.85,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Text('No data available'),
            );
          } else {
            final campaign = Campaign.fromFirestore(snapshot.data!);
            final volunteerCount = int.parse(campaign.currentVolunteers);
            final totalVolunteers = int.parse(campaign.volunteer);
            final remainingVolunteers = totalVolunteers - volunteerCount;

            DateTime dateStart = campaign.dateTimeStart;
            DateTime dateEnd = campaign.dateTimeEnd;
            String formattedTime = DateFormat('h:mm a').format(dateStart);
            String formattedDateStart = DateFormat('dd MMM yy').format(dateStart);
            String formattedDateEnd = DateFormat('dd MMM yy').format(dateEnd);
            String formattedSingleDate = DateFormat('dd MMM yy').format(dateEnd);

            List<dynamic> usersPromotedList = campaign.numUsersPromoted;
            int numUsersPromoted = getTotalPromotedCount(usersPromotedList);
            double participatePercent = (volunteerCount/numUsersPromoted)*100;
            List<Map<String, dynamic>> convertedList =  List<Map<String, dynamic>>.from(usersPromotedList);

            final data = [
              VolunteerData('Registered', volunteerCount),
              VolunteerData('Needed', remainingVolunteers),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: size.height*0.18,
                  width: size.width,
                  margin: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: size.width *0.50,
                        decoration: BoxDecoration(
                          color: mainBackColor,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 3.0,
                              spreadRadius: 1.0,
                              offset: Offset(0, 3), // Adjust the offset as needed
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: RichText(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Title: ',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        color: orgMainColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      text: campaign.title,
                                      style: const TextStyle(
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
                            Padding(
                              padding: const EdgeInsets.only(left: 10,right: 10,bottom: 10),
                              child: RichText(
                                maxLines: 2,
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Category: ',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        color: orgMainColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      text: campaign.category,
                                      style: const TextStyle(
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
                          ],
                        )
                      ),
                      Container(
                        width: size.width*0.35,
                          decoration: BoxDecoration(
                            color: mainBackColor,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3.0,
                                spreadRadius: 1.0,
                                offset: Offset(0, 3), // Adjust the offset as needed
                              ),
                            ],
                          ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                           crossAxisAlignment: CrossAxisAlignment.center,
                           mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.place_sharp, size: 30, color: orgMainColor),
                              const Text(
                                'Geofence: ',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: orgMainColor,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatRadius(campaign.geoFenceRadius),
                                  style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.normal,
                                  color: mainTextColor,
                                  fontSize: 14,
                               ),
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.only(left: 10,right: 10,bottom: 10),
                              //   child: RichText(
                              //     maxLines: 1,
                              //     text: TextSpan(
                              //       children: [
                              //         const TextSpan(
                              //           text: 'Date: ',
                              //           style: TextStyle(
                              //             fontFamily: 'Poppins',
                              //             fontWeight: FontWeight.bold,
                              //             color: orgMainColor,
                              //             fontSize: 14,
                              //           ),
                              //         ),
                              //         TextSpan(
                              //           text: dateEnd.difference(dateStart).inDays > 0
                              //               ? formattedDateStart + ' - ' + formattedDateEnd
                              //               : formattedSingleDate,
                              //           style: const TextStyle(
                              //             fontFamily: 'Poppins',
                              //             color: mainTextColor,
                              //             fontSize: 12.0,
                              //           ),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
                Container(
                  height: size.height*0.12,
                  width: size.width,
                  margin: const EdgeInsets.only(left:15, right:15, top:10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: size.width *0.42,
                          decoration: BoxDecoration(
                            color: mainBackColor,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3.0,
                                spreadRadius: 1.0,
                                offset: Offset(0, 3), // Adjust the offset as needed
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children:  [
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: const Text(
                                  'Number of users promoted: ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: orgMainColor,
                                    fontSize: 14,
                                  ),
                                )
                              ),
                              Text(
                                numUsersPromoted.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: mainTextColor,
                                  fontSize: 14,
                                ),
                              )
                            ],
                          )
                      ),
                      Container(
                          width: size.width *0.42,
                          decoration: BoxDecoration(
                            color: mainBackColor,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3.0,
                                spreadRadius: 1.0,
                                offset: Offset(0, 3), // Adjust the offset as needed
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children:  [
                              Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: const Text(
                                    'Participate percentage: ',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      color: orgMainColor,
                                      fontSize: 14,
                                    ),
                                  )
                              ),
                              Text(
                                participatePercent.toStringAsFixed(2)+"%",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: mainTextColor,
                                  fontSize: 14,
                                ),
                              )
                            ],
                          )
                      ),
                    ],
                  ),
                ),
                Container(
                    height: size.height*0.60,
                    padding: const EdgeInsets.only(top: 15, left: 20, right: 20),
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          indicatorColor: orgMainColor,
                          indicatorPadding: EdgeInsets.only(bottom: 10),
                          labelColor: orgMainColor,
                          unselectedLabelColor: Colors.grey,
                          tabs: [
                            Container(
                              child: Tab(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Advertise Performance',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold,
                                        color: mainTextColor),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              child: Tab(
                                child: Text(
                                  'Volunteer Chart',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold,
                                      color: mainTextColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              BarChartWidget(convertedList),
                              PieChartWidget(data)
                            ],
                          ),
                        ),
                      ],
                    )
                )
              ],
            );
          }
        },
       ),
      )
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
