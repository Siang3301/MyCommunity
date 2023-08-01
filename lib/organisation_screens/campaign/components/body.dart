import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mycommunity/organisation_screens/campaign/components/campaign_detail.dart';
import 'package:mycommunity/organisation_screens/campaign/components/edit_campaign.dart';
import 'package:mycommunity/organisation_screens/campaign/components/search_field.dart';
import 'package:mycommunity/organisation_screens/campaign/model/campaign.dart';
import 'package:mycommunity/organisation_screens/profile/components/account_management.dart';
import 'package:mycommunity/organisation_screens/profile/organisation_preview.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/organisation_screens/campaign/components/background.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart' as smtp;
import 'package:intl/intl.dart';

class OrganisationCampaignBody extends StatefulWidget{
  const OrganisationCampaignBody({Key? key}) : super(key: key);

  @override
  _OrganisationCampaignBody createState() => _OrganisationCampaignBody();
}

class _OrganisationCampaignBody extends State<OrganisationCampaignBody>
    with TickerProviderStateMixin{

  final _formKey = GlobalKey<FormState>();
  TabController? _tabController;
  int selectedTabIndex = 0;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '', organizerName = '';
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

  Future<void> archiveCampaign(String campaignId, String userId) async {
    final campaignRef = FirebaseFirestore.instance.collection('campaigns').doc(campaignId);

    // Retrieve the campaign document
    final campaignDoc = await campaignRef.get();

    if (campaignDoc.exists) {

      // Update the 'is_archived' attribute to true
      await campaignRef.update({'is_archived': true});

      final archiveRef = FirebaseFirestore.instance.collection('users_data').doc(userId).collection('archived_campaign');
      final archivedCampaignData = Campaign.fromFirestore(campaignDoc);

      // Save the archived campaign document
      archivedCampaignData.isArchived = true;
      await archiveRef.doc(campaignId).set(archivedCampaignData.toJson());

      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success', style: TextStyle(fontFamily: 'Raleway')),
            content: Text('You have successfully archived the campaign!', style: TextStyle(fontFamily: 'Raleway')),
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


    } else {
      // Campaign document does not exist
      throw Exception('Campaign with ID $campaignId does not exist.');
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
          organizerName = value['organisation_name'];
        });
      }
    });
  }

  void _deleteCampaign(BuildContext context, String campaignID, String organizerId, String campaignTitle, List<dynamic> joinedUserIds) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
            'Are you sure you want to cancel this campaign? All your participants will receive a cancellation email after you cancel the campaign.',
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
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Cancelling campaign...', style: TextStyle(fontFamily:'Raleway')),
                ],
              ),
            );
          },
        );

        getOrganizerDetail(organizerId);
        FirebaseFirestore.instance.collection('campaigns').doc(campaignID).delete().then((_) {
          for (var user in joinedUserIds) {
            var userId = user['userId'];
            FirebaseFirestore.instance
                .collection('users_data')
                .doc(userId)
                .collection('user_activities')
                .where('activityId', isEqualTo: campaignID)
                .get()
                .then((querySnapshot) {
              if (querySnapshot.docs.isNotEmpty) {
                final reminderId = querySnapshot.docs.first.get('reminderId') as int;
                querySnapshot.docs.first.reference.delete();
                cancelReminder(reminderId);
              }
            });

            FirebaseFirestore.instance
                .collection('users_data')
                .doc(userId)
                .collection('users_notification')
                .doc(campaignID)
                .get()
                .then((doc) {
              if (doc.exists) {
                doc.reference.delete().then((_) {
                  // Document successfully deleted
                  print("Document deleted from users_notification collection");
                }).catchError((error) {
                  print("Error deleting document from users_notification: $error");
                });
              } else {
                // Document does not exist
                print("Document does not exist in users_notification collection");
              }
            }).catchError((error) {
              print("Error getting document from users_notification: $error");
            });

            FirebaseFirestore.instance
                .collection('users_data')
                .doc(userId)
                .get()
                .then((userSnapshot) {
              if (userSnapshot.exists) {
                var userEmail = userSnapshot.data()!['email'];
                var userName = userSnapshot.data()!['username'];
                sendCancellationEmail(userEmail, userName, campaignTitle, organizerName);
              }
            });
          }
        }).catchError((error) {
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred while deleting the campaign: $error'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        });

        Navigator.of(context).pop();
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text(
                  'Campaign Deleted',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                content: Text(
                  'The campaign has been successfully cancelled. All participants will be informed via email.',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 14,
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            }
        );
      }
    });
  }

  void sendCancellationEmail(String userEmail, String userName, String activityTitle, String organizerName) async {
    final smtpServer = smtp.gmail('mycommunity.managament@gmail.com', 'qjszowtofbwowdwq');
    // Replace 'your_email_address' with your actual email address and 'your_password' with your email password.

    final emailMessage = mailer.Message()
      ..from = mailer.Address('mycommunity.managament@gmail.com')
      ..recipients.add(userEmail)
      ..subject = 'Campaign Cancellation'
      ..text =
          'Dear $userName,\n\nWe regret to inform you that the campaign "$activityTitle" has been cancelled by organisation "$organizerName". Please accept our apologies for any inconvenience caused.\n\nThanks,\nToward make a better community,\nMyCommunity Management Team.'

      ..html = '''
    <p>Dear $userName,</p>
    <p>We regret to inform you that the campaign "$activityTitle" has been cancelled by organisation "$organizerName". Please accept our apologies for any inconvenience caused.</p>
    <p>Thanks,<br>
    Toward make a better community,<br>
    MyCommunity Management Team.</p>
''';

    try {
      final sendReport = await mailer.send(emailMessage, smtpServer);
      print('Cancellation email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending cancellation email: $e');
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
        backgroundColor: mainBackColor,
        appBar : AppBar(
         centerTitle: false,
          title:  const Text("My Campaign", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
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
                     ? Container(margin: const EdgeInsets.only(right: 15), child: const Icon(Icons.account_circle_rounded, color: kPrimaryColor, size: 26))
                     : Container(
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
                                             Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: document.id)));
                                           },
                                           child: Column(
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
                                                               Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: document.id)));
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
                                                       Column(
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
                                                       Column(
                                                         crossAxisAlignment: CrossAxisAlignment.start,
                                                         children: [
                                                           IconButton(
                                                             icon: const Icon(Icons.edit, color: orgMainColor),
                                                             onPressed: () {
                                                               Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditCampaign(campaignID: document.id)));// Implement edit campaign function
                                                             },
                                                           ),
                                                           IconButton(
                                                             icon: const Icon(Icons.delete, color: orgMainColor),
                                                             onPressed: () {
                                                               _deleteCampaign(context, document.id, document['organizerID'], document['title'], document['joinedUserIds']);
                                                             },
                                                           ),
                                                         ],
                                                       ),
                                                     ],
                                                   ),
                                                 ),
                                                 const SizedBox(height: 5),
                                               ]
                                           ),
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
                                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: document.id)));
                                                },
                                                child: Stack(
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
                                                                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: document.id)));
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
                                                            Column(
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
                                                            Column(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                IconButton(
                                                                  icon: const Icon(Icons.archive, color: orgMainColor),
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
                                                                                    "Archiving campaign...",
                                                                                    style: TextStyle(fontFamily: 'Raleway'),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            );
                                                                          },
                                                                        );

                                                                        try {
                                                                          // Call joinEvent and addUserActivity
                                                                          await archiveCampaign(document.id, auth.getCurrentUID());

                                                                        } catch (e) {
                                                                          // Hide loading dialog and show error dialog
                                                                          Navigator.of(context).pop();
                                                                          showDialog(
                                                                            context: context,
                                                                            builder: (BuildContext context) {
                                                                              return AlertDialog(
                                                                                title: Text('Error', style: TextStyle(fontFamily: 'Raleway')),
                                                                                content: Text('An error occurred while archiving the campaign.', style: TextStyle(fontFamily: 'Raleway')),
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
                                                                ),
                                                              ],
                                                            ),
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
                                                ),
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
          'Are you sure you want to archive this campaign? The campaign will move to archive space after you archived it.',
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
              'Yes!',
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




