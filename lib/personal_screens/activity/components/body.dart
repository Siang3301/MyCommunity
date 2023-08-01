import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/edit_event.dart';
import 'package:mycommunity/personal_screens/home/components/event_detail.dart';
import 'package:mycommunity/personal_screens/activity/model/activity.dart';
import 'package:mycommunity/personal_screens/home/components/campaign_detail.dart';
import 'package:mycommunity/personal_screens/home/components/search_field.dart';
import 'package:mycommunity/personal_screens/profile/profile_preview.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/personal_screens/profile/components/account_management.dart';
import 'package:mycommunity/personal_screens/activity//components/background.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:intl/intl.dart';

import '../../home/components/model/campaign_all.dart';
import '../../home/components/model/event_all.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart' as smtp;

class PersonalActivityBody extends StatefulWidget{
  const PersonalActivityBody({Key? key}) : super(key: key);

  @override
  _PersonalActivityBody createState() => _PersonalActivityBody();
}

class _PersonalActivityBody extends State<PersonalActivityBody>
    with TickerProviderStateMixin{
  final _formKey = GlobalKey<FormState>();
  String _searchQuery = '';
  String organizerName = '';
  int selectedTabIndex = 0;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  void getOrganizerDetail(String organizerID) async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    await db
        .collection('users_data')
        .doc(organizerID)
        .get()
        .then((value) {
      if(mounted) {
        setState(() {
          organizerName = value['username'];
        });
      }
    });
  }

  void _deleteEvent(BuildContext context, String eventID, String organizerId, String eventTitle, List<dynamic> joinedUserIds) {
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
            'Are you sure you want to cancel this event? All your participants will receive a cancellation email after you cancel the event.',
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
                  Text('Cancelling event...', style: TextStyle(fontFamily:'Raleway')),
                ],
              ),
            );
          },
        );

        getOrganizerDetail(organizerId);
        FirebaseFirestore.instance.collection('events').doc(eventID).delete().then((_) {
          for (var user in joinedUserIds) {
            var userId = user['userId'];
            FirebaseFirestore.instance
                .collection('users_data')
                .doc(userId)
                .collection('user_activities')
                .where('activityId', isEqualTo: eventID)
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
                .doc(eventID)
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
                sendCancellationEmail(userEmail, userName, eventTitle, organizerName);
              }
            });
          }
        }).catchError((error) {
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred while deleting the event: $error'),
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
                  'Event Deleted',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                content: Text(
                  'The event has been successfully cancelled. All participants will be informed via email.',
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
      ..subject = 'Individual Event Cancellation'
      ..text =
          'Dear $userName,\n\nWe regret to inform you that the event "$activityTitle" has been cancelled by organizer/creator "$organizerName". Please accept our apologies for any inconvenience caused.\n\nThanks,\nToward make a better community,\nMyCommunity Management Team.'

      ..html = '''
    <p>Dear $userName,</p>
    <p>We regret to inform you that the event "$activityTitle" has been cancelled by organizer/creator "$organizerName". Please accept our apologies for any inconvenience caused.</p>
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

  Future<void> archiveEvent(String eventId, String userId) async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);

    // Retrieve the campaign document
    final eventDoc = await eventRef.get();

    if (eventDoc.exists) {

      // Update the 'is_archived' attribute to true
      await eventRef.update({'is_archived': true});

      final archiveRef = FirebaseFirestore.instance.collection('users_data').doc(userId).collection('archived_event');
      final archivedEventData = Event.fromFirestore(eventDoc);

      // Save the archived campaign document
      archivedEventData.isArchived = true;
      await archiveRef.doc(eventId).set(archivedEventData.toJson());

      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success', style: TextStyle(fontFamily: 'Raleway')),
            content: Text('You have successfully archived the event!', style: TextStyle(fontFamily: 'Raleway')),
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
      throw Exception('Event with ID $eventId does not exist.');
    }
  }

  Stream<List<Activity>> getSortedActivitiesStream(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    final activitiesCollection = FirebaseFirestore.instance
        .collection('users_data')
        .doc(auth.getCurrentUID())
        .collection('user_activities');

    return activitiesCollection.snapshots().asyncMap((querySnapshot) async {
      final activities = querySnapshot.docs
          .map((doc) => Activity.fromDoc(doc))
          .where((activity) => activity.type != null)
          .toList();

      final currentActivities = <Activity>[];

      for (final activity in activities) {
        if (activity.type == ActivityType.event) {
          final eventDoc = await FirebaseFirestore.instance
              .collection('events')
              .doc(activity.id)
              .get();
          final eventData = Event.fromFirestore(eventDoc);
          if (eventData != null &&
              !eventData.isCompleted &&
              eventData.dateTimeEnd != null &&
              eventData.dateTimeEnd.isAfter(DateTime.now())) {
            activity.date_time_start = eventData.dateTimeStart;
            activity.name = eventData.title;
            activity.activityStatus = eventData.isCompleted;
            currentActivities.add(activity);
          }
        } else if (activity.type == ActivityType.campaign) {
          final campaignDoc = await FirebaseFirestore.instance
              .collection('campaigns')
              .doc(activity.id)
              .get();
          final campaignData = Campaign.fromFirestore(campaignDoc);
          if (campaignData != null &&
              !campaignData.isCompleted &&
              campaignData.dateTimeEnd != null &&
              campaignData.dateTimeEnd.isAfter(DateTime.now())) {
            activity.date_time_start = campaignData.dateTimeStart;
            activity.name = campaignData.title;
            activity.activityStatus = campaignData.isCompleted;
            currentActivities.add(activity);
          }
        }
      }

      currentActivities.sort((a, b) => a.date_time_start!.compareTo(b.date_time_start!));

      return currentActivities;
    });
  }

  Future<void> archiveActivity(String activityType, String activityId, String userId) async {
    final activityRef = FirebaseFirestore.instance.collection(activityType).doc(activityId);

    // Retrieve the campaign document
    final activityDoc = await activityRef.get();

    if (activityDoc.exists) {

      // Update the 'is_archived' attribute to true
      List<dynamic> joinedUserIds = activityDoc.data()!['joinedUserIds'];
      int userIndex = joinedUserIds.indexWhere((user) => user['userId'] == userId);

      if (userIndex != -1) {
        // Update the is_archived status to true for the user at the specified index
        joinedUserIds[userIndex]['is_archived'] = true;
        // Update the campaign document with the modified joinedUserIds array
        await activityRef.update({'joinedUserIds': joinedUserIds});
      } else {
        // User not found in the joinedUserIds array
        throw Exception('User with ID $userId is not joined in the campaign.');
      }

      if(activityType == 'campaigns') {
        final archiveRef = FirebaseFirestore.instance.collection('users_data')
            .doc(userId).collection('archived_activities_campaign');

        final archivedCampaignData = Campaign.fromFirestore(activityDoc);

        // Save the archived campaign document
        archivedCampaignData.joinedUserIds = joinedUserIds;
        archivedCampaignData.isArchived = true;
        await archiveRef.doc(activityId).set(archivedCampaignData.toJson());
      }
      else{
        final archiveRef = FirebaseFirestore.instance.collection('users_data')
            .doc(userId).collection('archived_activities_event');

        final archivedEventData = Event.fromFirestore(activityDoc);

        // Save the archived campaign document
        archivedEventData.joinedUserIds = joinedUserIds;
        archivedEventData.isArchived = true;
        await archiveRef.doc(activityId).set(archivedEventData.toJson());
      }

      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success', style: TextStyle(fontFamily: 'Raleway')),
            content: Text('You have successfully archived the activity!', style: TextStyle(fontFamily: 'Raleway')),
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
      throw Exception('Activity with ID $activityId does not exist.');
    }
  }

  Stream<List<Activity>> getPastActivitiesStream(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    final activitiesCollection = FirebaseFirestore.instance
        .collection('users_data')
        .doc(auth.getCurrentUID())
        .collection('user_activities');

    return activitiesCollection.snapshots().asyncMap((querySnapshot) async {
      final activities = querySnapshot.docs
          .map((doc) => Activity.fromDoc(doc))
          .where((activity) => activity.type != null)
          .toList();

      final campaigns = activities
          .where((activity) => activity.type == ActivityType.campaign)
          .map((activity) => activity.id)
          .toList();

      final events = activities
          .where((activity) => activity.type == ActivityType.event)
          .map((activity) => activity.id)
          .toList();

      for (final activity in activities) {
        if (activity.type == ActivityType.event) {
          final snapshot = await FirebaseFirestore.instance
              .collection('events')
              .doc(activity.id)
              .get();
          final eventData = Event.fromFirestore(snapshot);
          activity.date_time_start = eventData.dateTimeStart;
          activity.date_time_end = eventData.dateTimeEnd;
          activity.name = eventData.title;
          activity.activityStatus = eventData.isCompleted;
          activity.joinedUserIds = eventData.joinedUserIds;
        } else if (activity.type == ActivityType.campaign) {
          final snapshot = await FirebaseFirestore.instance
              .collection('campaigns')
              .doc(activity.id)
              .get();
          final campaignData = Campaign.fromFirestore(snapshot);
          activity.date_time_start = campaignData.dateTimeStart;
          activity.date_time_end = campaignData.dateTimeEnd;
          activity.name = campaignData.title;
          activity.activityStatus = campaignData.isCompleted;
          activity.joinedUserIds = campaignData.joinedUserIds;
        }
      }

      final pastActivities = activities.where((activity) {
        if (activity.activityStatus == true &&
            activity.date_time_end != null &&
            activity.date_time_end!.isBefore(DateTime.now())) {

          final joinedUser = activity.joinedUserIds
              ?.firstWhere((user) => user['userId'] == auth.getCurrentUID(), orElse: () => null);

          if (joinedUser != null && joinedUser['is_archived'] == true) {
            // Exclude activities where the joinedUser has is_archived = true
            return false;
          }

          return true;
        } else {
          return false;
        }
      }).toList();

      pastActivities.sort((a, b) => b.date_time_end!.compareTo(a.date_time_end!));

      return pastActivities;
    });
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
      final userActivityRef = collectionRef.doc(querySnapshot.docs.first.id);
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

  Future<void> cancelCampaign(String eventId, String userId) async {
    final campaignRef = FirebaseFirestore.instance.collection('campaigns').doc(eventId);

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

      // Remove UserActivity
      await removeUserActivity(userId, eventId);

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
                },
              ),
            ],
          );
        },
      );
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
          title: const Text("My Activities", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
          backgroundColor: Colors.white,
           bottomOpacity: 0.0,
           elevation: 0.0,
           actions: <Widget>[
             InkWell(
                 onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalProfilePreview(userId: auth.getCurrentUID())));
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
                  Stack(
                    children: [
                      Container(
                        color: Colors.white,
                        height: size.height*0.20,
                        padding: const EdgeInsets.only(left: 20, top: 10),
                        width: size.width,
                      ),
                      SizedBox(height: 5),
                      Padding(
                        padding: EdgeInsets.only(left: 25),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.grey[300],
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icons/campaign.png',
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Campaign',
                                style: TextStyle(fontSize: 12, fontFamily: 'Raleway', fontWeight: FontWeight.bold, color: kPrimaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.grey[300],
                                child: ClipOval(
                                  child: Padding(
                                    padding: EdgeInsets.all(5),
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
                                  child: Image.asset(
                                    'assets/icons/event.png',
                                    fit: BoxFit.cover,
                                    color: kPrimaryColor,
                                    width: 80,
                                    height: 80,
                                   ),
                                  )
                                 ),
                                )
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Event',
                                style: TextStyle(fontSize: 12, fontFamily: 'Raleway', fontWeight: FontWeight.bold, color: kPrimaryColor),
                              ),
                            ],
                          ),
                        ],
                       ),
                      ),
                      Container(
                          padding: EdgeInsets.only(left: 10, right: 10),
                          alignment: Alignment.bottomCenter,
                          height: size.height*0.14,
                          child: SearchField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          )
                      ),
                      Container(
                          height: size.height*0.8,
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Column(
                            children: [
                              SizedBox(height: size.height*0.15),
                              TabBar(
                                controller: _tabController,
                                indicatorColor: kPrimaryColor,
                                labelColor: kPrimaryColor,
                                unselectedLabelColor: Colors.grey,
                                indicatorPadding: EdgeInsets.only(bottom: 10),
                                labelPadding: EdgeInsets.zero,
                                tabs: [
                                  Container(
                                    child: Tab(
                                      child: Text(
                                        'Current Activities',
                                        style: TextStyle(fontFamily: 'Raleway', fontSize: 10, fontWeight: FontWeight.bold,
                                          color: _tabController?.index == 0 ? kPrimaryColor : mainTextColor),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Tab(
                                      child: Text(
                                        'Past Activities',
                                        style: TextStyle(fontFamily: 'Raleway', fontSize: 10, fontWeight: FontWeight.bold,
                                            color: _tabController?.index == 1 ? kPrimaryColor : mainTextColor),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Tab(
                                      child: Text(
                                        'My Event',
                                        style: TextStyle(fontFamily: 'Raleway', fontSize: 10, fontWeight: FontWeight.bold,
                                            color: _tabController?.index == 2 ? kPrimaryColor : mainTextColor),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Tab(
                                      child: Text(
                                        'My Past Event',
                                        style: TextStyle(fontFamily: 'Raleway', fontSize: 10, fontWeight: FontWeight.bold,
                                            color: _tabController?.index == 3 ? kPrimaryColor : mainTextColor),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Flexible(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    // Current Joined Activities
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child:
                                      StreamBuilder<List<Activity>>(
                                        stream: getSortedActivitiesStream(context),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              final sortedActivities = snapshot.data!;

                                              // Filter campaigns based on search query
                                              List<Activity> filteredDocs = [];

                                              sortedActivities.forEach((doc) {
                                                bool matchesQuery = false;
                                                if (doc.name!.toLowerCase().contains(_searchQuery.toLowerCase())) {
                                                  matchesQuery = true;
                                                }
                                                if (matchesQuery) {
                                                  filteredDocs.add(doc);
                                                }
                                              });

                                              if (sortedActivities.isEmpty){
                                                return const Center(child:Text('Currently you have no join any activities.', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                              }
                                              if (filteredDocs.isEmpty) {
                                                return Center(child:Text('No activities found for "${_searchQuery}"', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                              }

                                              return Column(
                                                children: [
                                                  if (sortedActivities.isNotEmpty)
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        SizedBox(
                                                          height: size.height * 0.55,
                                                          child: ListView.builder(
                                                            shrinkWrap: true,
                                                            itemCount: filteredDocs.length,
                                                            itemBuilder: (context, index) {
                                                              final activity = filteredDocs[index];
                                                              if (activity.type == ActivityType.campaign) {
                                                                return FutureBuilder<DocumentSnapshot>(
                                                                  future: FirebaseFirestore.instance.collection('campaigns').doc(activity.id).get(),
                                                                  builder: (context, snapshot) {
                                                                    if (snapshot.hasData) {
                                                                      final campaignData = Campaign.fromFirestore(snapshot.data!);
                                                                      DateTime dateStart = campaignData.dateTimeStart;
                                                                      DateTime dateEnd = campaignData.dateTimeEnd;
                                                                      String formattedTime = DateFormat('h:mm a').format(dateStart);
                                                                      String formattedDateStart = DateFormat('dd MMM yy').format(dateStart);
                                                                      String formattedDateEnd = DateFormat('dd MMM yy').format(dateEnd);
                                                                      String formattedSingleDate = DateFormat('dd MMM yy').format(dateEnd);

                                                                      return GestureDetector(
                                                                          onTap: (){
                                                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: activity.id)));
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
                                                                                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: activity.id)));
                                                                                        },
                                                                                        child: CircleAvatar(
                                                                                          radius: 30,
                                                                                          backgroundImage: CachedNetworkImageProvider(campaignData.imageUrl),
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
                                                                                            campaignData.title,
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
                                                                                            campaignData.description,
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
                                                                                            '${campaignData.currentVolunteers}/${campaignData.volunteer}',
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
                                                                                        icon: const Icon(Icons.cancel, color: kPrimaryColor),
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
                                                                                                await cancelCampaign(activity.id, auth.getCurrentUID());

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
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 5),
                                                                            Positioned(
                                                                              top:0,
                                                                              left:0,
                                                                              child:CircleAvatar(
                                                                                radius: 15,
                                                                                backgroundColor: Colors.grey[300],
                                                                                child: ClipOval(
                                                                                  child: Image.asset(
                                                                                    'assets/icons/campaign.png',
                                                                                    fit: BoxFit.cover,
                                                                                    width: 30,
                                                                                    height: 30,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            )
                                                                          ]
                                                                          )
                                                                         );
                                                                        } else if (snapshot.hasError) {
                                                                         return const Center(child:Text('Error loading campaign data', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                                                        } else {
                                                                          return const Center(
                                                                            child: CircularProgressIndicator(),
                                                                          );
                                                                        }
                                                                      },
                                                                    );
                                                                  } else if (activity.type == ActivityType.event) {
                                                                    return FutureBuilder<DocumentSnapshot>(
                                                                      future: FirebaseFirestore.instance.collection('events').doc(activity.id).get(),
                                                                      builder: (context, snapshot) {
                                                                        if (snapshot.hasData) {
                                                                          final eventData = Event.fromFirestore(snapshot.data!);
                                                                          DateTime dateStart = eventData.dateTimeStart;
                                                                          DateTime dateEnd = eventData.dateTimeEnd;
                                                                          String formattedTime = DateFormat('h:mm a').format(dateStart);
                                                                          String formattedDateStart = DateFormat('dd MMM yy').format(dateStart);
                                                                          String formattedDateEnd = DateFormat('dd MMM yy').format(dateEnd);
                                                                          String formattedSingleDate = DateFormat('dd MMM yy').format(dateEnd);

                                                                          return GestureDetector(
                                                                              onTap: (){
                                                                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: activity.id)));
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
                                                                                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: activity.id)));
                                                                                            },
                                                                                            child: CircleAvatar(
                                                                                              radius: 30,
                                                                                              backgroundImage: CachedNetworkImageProvider(eventData.imageUrl),
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
                                                                                                eventData.title,
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
                                                                                                eventData.description,
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
                                                                                                '${eventData.currentVolunteers}/${eventData.volunteer}',
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
                                                                                            icon: const Icon(Icons.cancel, color: kPrimaryColor),
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
                                                                                                    await cancelEvent(activity.id, auth.getCurrentUID());

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
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 5),
                                                                                Positioned(
                                                                                  top:0,
                                                                                  left:0,
                                                                                  child:CircleAvatar(
                                                                                    radius: 15,
                                                                                    backgroundColor: Colors.grey[300],
                                                                                    child:Padding(
                                                                                      padding: EdgeInsets.all(5),
                                                                                    child: ClipOval(
                                                                                      child: Image.asset(
                                                                                        'assets/icons/event.png',
                                                                                        fit: BoxFit.cover,
                                                                                        width: 30,
                                                                                        height: 30,
                                                                                        color: kPrimaryColor,
                                                                                      ),
                                                                                    ),
                                                                                   ),
                                                                                  )
                                                                                )
                                                                              ]
                                                                            )
                                                                          );
                                                                        } else if (snapshot.hasError) {
                                                                          return const Center(child:Text('Error loading event data', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                                                        } else {
                                                                          return const Center(
                                                                            child: CircularProgressIndicator(),
                                                                          );
                                                                        }
                                                                      },
                                                                    );
                                                            } else {
                                                              return const SizedBox.shrink();
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            );
                                          } else if (snapshot.hasError) {
                                              return Center(child:Text('Error loading activities: ${snapshot.error}', style: const TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                          } else {
                                            return const Center(
                                              child: CircularProgressIndicator(),
                                            );
                                          }
                                        },
                                      )
                                    ),

                                    // Past Joined Activities
                                    Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child:
                                        StreamBuilder<List<Activity>>(
                                          stream: getPastActivitiesStream(context),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              final sortedActivities = snapshot.data!;

                                              // Filter campaigns based on search query
                                              List<Activity> filteredDocs = [];

                                              sortedActivities.forEach((doc) {
                                                bool matchesQuery = false;
                                                if (doc.name!.toLowerCase().contains(_searchQuery.toLowerCase())) {
                                                  matchesQuery = true;
                                                }
                                                if (matchesQuery) {
                                                  filteredDocs.add(doc);
                                                }
                                              });

                                              if (sortedActivities.isEmpty){
                                                return const Center(child:Text('Currently you have no past activities.', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                              }
                                              if (filteredDocs.isEmpty) {
                                                return Center(child:Text('No past activities found for "${_searchQuery}"', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                              }

                                              return Column(
                                                children: [
                                                  if (sortedActivities.isNotEmpty)
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        SizedBox(
                                                          height: size.height * 0.55,
                                                          child: ListView.builder(
                                                            shrinkWrap: true,
                                                            itemCount: filteredDocs.length,
                                                            itemBuilder: (context, index) {
                                                              final activity = filteredDocs[index];
                                                              if (activity.type == ActivityType.campaign) {
                                                                return FutureBuilder<DocumentSnapshot>(
                                                                  future: FirebaseFirestore.instance.collection('campaigns').doc(activity.id).get(),
                                                                  builder: (context, snapshot) {
                                                                    if (snapshot.hasData) {
                                                                      final campaignData = Campaign.fromFirestore(snapshot.data!);
                                                                      DateTime dateStart = campaignData.dateTimeStart;
                                                                      DateTime dateEnd = campaignData.dateTimeEnd;
                                                                      String formattedTime = DateFormat('h:mm a').format(dateStart);
                                                                      String formattedDateStart = DateFormat('dd MMM yy').format(dateStart);
                                                                      String formattedDateEnd = DateFormat('dd MMM yy').format(dateEnd);
                                                                      String formattedSingleDate = DateFormat('dd MMM yy').format(dateEnd);

                                                                      return GestureDetector(
                                                                        onTap: (){
                                                                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: activity.id)));
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
                                                                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: activity.id)));
                                                                                        },
                                                                                        child: CircleAvatar(
                                                                                          radius: 30,
                                                                                          backgroundImage: CachedNetworkImageProvider(campaignData.imageUrl),
                                                                                        ),
                                                                                      )
                                                                                  ),
                                                                                  Expanded(
                                                                                    child: Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Container(
                                                                                          width: size.width*0.25,
                                                                                          padding: const EdgeInsets.only(top: 15, right: 10),
                                                                                          margin: EdgeInsets.only(bottom: 10),
                                                                                          child: Text(
                                                                                            campaignData.title,
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
                                                                                          width: size.width*0.25,
                                                                                          padding: const EdgeInsets.only(right: 10),
                                                                                          margin: EdgeInsets.only(bottom: 20),
                                                                                          child: Text(
                                                                                            campaignData.description,
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
                                                                                            '${campaignData.currentVolunteers}/${campaignData.volunteer}',
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
                                                                                        icon: const Icon(Icons.archive, color: kPrimaryColor),
                                                                                        onPressed: () {
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
                                                                                                          "Archiving campaign activity...",
                                                                                                          style: TextStyle(fontFamily: 'Raleway'),
                                                                                                        ),
                                                                                                      ],
                                                                                                    ),
                                                                                                  );
                                                                                                },
                                                                                              );

                                                                                              try {
                                                                                                // Call joinEvent and addUserActivity
                                                                                                setState(() {
                                                                                                   archiveActivity( 'campaigns' , activity.id, auth.getCurrentUID());
                                                                                                });

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
                                                                              top:0,
                                                                              left:0,
                                                                              child:CircleAvatar(
                                                                                radius: 15,
                                                                                backgroundColor: Colors.grey[300],
                                                                                child: ClipOval(
                                                                                  child: Image.asset(
                                                                                    'assets/icons/campaign.png',
                                                                                    fit: BoxFit.cover,
                                                                                    width: 30,
                                                                                    height: 30,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            Positioned(
                                                                              right: 0,
                                                                              top:-5,
                                                                              child: campaignData.isCompleted ? ImageIcon(
                                                                                AssetImage('assets/icons/campaign_complete.png'),
                                                                                color: Colors.green,
                                                                                size: 40,
                                                                              ) : Container(),
                                                                            ),
                                                                          ]
                                                                        )
                                                                      );
                                                                    } else if (snapshot.hasError) {
                                                                      return const Center(child:Text("Error loading campaign data", style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                                                    } else {
                                                                      return const Center(
                                                                        child: CircularProgressIndicator(),
                                                                      );
                                                                    }
                                                                  },
                                                                );
                                                              } else if (activity.type == ActivityType.event) {
                                                                return FutureBuilder<DocumentSnapshot>(
                                                                  future: FirebaseFirestore.instance.collection('events').doc(activity.id).get(),
                                                                  builder: (context, snapshot) {
                                                                    if (snapshot.hasData) {
                                                                      final eventData = Event.fromFirestore(snapshot.data!);
                                                                      DateTime dateStart = eventData.dateTimeStart;
                                                                      DateTime dateEnd = eventData.dateTimeEnd;
                                                                      String formattedTime = DateFormat('h:mm a').format(dateStart);
                                                                      String formattedDateStart = DateFormat('dd MMM yy').format(dateStart);
                                                                      String formattedDateEnd = DateFormat('dd MMM yy').format(dateEnd);
                                                                      String formattedSingleDate = DateFormat('dd MMM yy').format(dateEnd);

                                                                      return GestureDetector(
                                                                          onTap: (){
                                                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: activity.id)));
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
                                                                                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: activity.id)));
                                                                                        },
                                                                                        child: CircleAvatar(
                                                                                          radius: 30,
                                                                                          backgroundImage: CachedNetworkImageProvider(eventData.imageUrl),
                                                                                        ),
                                                                                      )
                                                                                  ),
                                                                                  Expanded(
                                                                                    child: Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: [
                                                                                        Container(
                                                                                          width: size.width * 0.25,
                                                                                          padding: const EdgeInsets.only(top: 15, right: 10),
                                                                                          margin: EdgeInsets.only(bottom: 10),
                                                                                          child: Text(
                                                                                            eventData.title,
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
                                                                                          width: size.width * 0.25,
                                                                                          padding: const EdgeInsets.only(right: 10),
                                                                                          margin: EdgeInsets.only(bottom: 20),
                                                                                          child: Text(
                                                                                            eventData.description,
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
                                                                                            '${eventData.currentVolunteers}/${eventData.volunteer}',
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
                                                                                        icon: const Icon(Icons.archive, color: kPrimaryColor),
                                                                                        onPressed: () {
                                                                                          showDoubleConfirmDialog_5(context).then((confirmed) async {
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
                                                                                                          "Archiving event activity...",
                                                                                                          style: TextStyle(fontFamily: 'Raleway'),
                                                                                                        ),
                                                                                                      ],
                                                                                                    ),
                                                                                                  );
                                                                                                },
                                                                                              );

                                                                                              try {
                                                                                                // Call joinEvent and addUserActivity
                                                                                                setState(() {
                                                                                                  archiveActivity( 'events' , activity.id, auth.getCurrentUID());
                                                                                                });

                                                                                              } catch (e) {
                                                                                                // Hide loading dialog and show error dialog
                                                                                                Navigator.of(context).pop();
                                                                                                showDialog(
                                                                                                  context: context,
                                                                                                  builder: (BuildContext context) {
                                                                                                    return AlertDialog(
                                                                                                      title: Text('Error', style: TextStyle(fontFamily: 'Raleway')),
                                                                                                      content: Text('An error occurred while archiving the event.', style: TextStyle(fontFamily: 'Raleway')),
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
                                                                              top:0,
                                                                              left:0,
                                                                              child:CircleAvatar(
                                                                                radius: 15,
                                                                                backgroundColor: Colors.grey[300],
                                                                                child: Padding(
                                                                                  padding: EdgeInsets.all(5),
                                                                                child: ClipOval(
                                                                                  child: Image.asset(
                                                                                    'assets/icons/event.png',
                                                                                    fit: BoxFit.cover,
                                                                                    width: 30,
                                                                                    height: 30,
                                                                                    color: kPrimaryColor,
                                                                                  ),
                                                                                 ),
                                                                                )
                                                                              ),
                                                                            ),
                                                                            Positioned(
                                                                              right: 0,
                                                                              top: -4,
                                                                              child: eventData.isCompleted ? ImageIcon(
                                                                                AssetImage('assets/icons/event_complete.png'),
                                                                                color: Colors.green,
                                                                                size: 40,
                                                                              ) : Container(),
                                                                            ),
                                                                          ]
                                                                        )
                                                                      );
                                                                    } else if (snapshot.hasError) {
                                                                      return const Center(child:Text("Error loading event data", style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                                                    } else {
                                                                      return const Center(
                                                                        child: CircularProgressIndicator(),
                                                                      );
                                                                    }
                                                                  },
                                                                );
                                                              } else {
                                                                return const SizedBox.shrink();
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              );
                                            } else if (snapshot.hasError) {
                                              return Center(child:Text('Error loading past activities: ${snapshot.error}', style: const TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                            } else {
                                              return const Center(
                                                child: CircularProgressIndicator(),
                                              );
                                            }
                                          },
                                        )
                                    ),

                                    // My current event
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Container(
                                          child: StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance.collection('events')
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
                                                return const Center(child:Text('You currently have no organize any event.', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                              }

                                              // Filter events based on search query
                                              List<QueryDocumentSnapshot> filteredDocs = [];
                                              snapshot.data!.docs.forEach((doc) {
                                                bool matchesQuery = false;
                                                if (doc['title'].toLowerCase().contains(_searchQuery.toLowerCase())) {
                                                  matchesQuery = true;
                                                } else if (doc['description'].toLowerCase().contains(_searchQuery.toLowerCase())) {
                                                  matchesQuery = true;
                                                }
                                                if (matchesQuery) {
                                                  filteredDocs.add(doc);
                                                }
                                              });

                                              if (filteredDocs.isEmpty) {
                                                return Center(child:Text('No events found for "${_searchQuery}"', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
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
                                                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: document.id)));
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
                                                                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: document.id)));
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
                                                                    icon: const Icon(Icons.edit, color: kPrimaryColor),
                                                                    onPressed: () {
                                                                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditEvent(eventID: document.id)));
                                                                    },
                                                                  ),
                                                                  IconButton(
                                                                    icon: const Icon(Icons.delete, color: kPrimaryColor),
                                                                    onPressed: () {
                                                                      _deleteEvent(context, document.id, document['organizerID'], document['title'], document['joinedUserIds']);
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
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

                                    // My past event
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Container(
                                          child: StreamBuilder<QuerySnapshot>(
                                            stream: FirebaseFirestore.instance.collection('events')
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
                                                return const Center(child:Text('You currently have no past organized events.', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
                                              }

                                              // Filter events based on search query
                                              List<QueryDocumentSnapshot> filteredDocs = [];
                                              snapshot.data!.docs.forEach((doc) {
                                                bool matchesQuery = false;
                                                if (doc['title'].toLowerCase().contains(_searchQuery.toLowerCase())) {
                                                  matchesQuery = true;
                                                } else if (doc['description'].toLowerCase().contains(_searchQuery.toLowerCase())) {
                                                  matchesQuery = true;
                                                }
                                                if (matchesQuery) {
                                                  filteredDocs.add(doc);
                                                }
                                              });

                                              if (filteredDocs.isEmpty) {
                                                return Center(child:Text('No events found for "${_searchQuery}"', style: TextStyle(fontFamily: 'SourceSansPro', fontSize: 13, color: mainTextColor)));
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
                                                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: document.id)));
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
                                                                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: document.id)));
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
                                                                    icon: const Icon(Icons.archive, color: kPrimaryColor),
                                                                    onPressed: () {
                                                                      showDoubleConfirmDialog_6(context).then((confirmed) async {
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
                                                                                      "Archiving event...",
                                                                                      style: TextStyle(fontFamily: 'Raleway'),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              );
                                                                            },
                                                                          );

                                                                          try {
                                                                            // Call joinEvent and addUserActivity
                                                                            await archiveEvent(document.id, auth.getCurrentUID());

                                                                          } catch (e) {
                                                                            // Hide loading dialog and show error dialog
                                                                            Navigator.of(context).pop();
                                                                            showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return AlertDialog(
                                                                                  title: Text('Error', style: TextStyle(fontFamily: 'Raleway')),
                                                                                  content: Text('An error occurred while archiving the event.', style: TextStyle(fontFamily: 'Raleway')),
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
                                                          top: -4,
                                                          left: 0,
                                                          child: document['is_completed'] ? ImageIcon(
                                                            AssetImage('assets/icons/event_complete.png'),
                                                            color: Colors.green,
                                                            size: 40,
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
                ],
              ),
            )
          ),
        )
     )
    );
  }
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
          'Are you sure you want to archive this campaign activity? You can still view the activity at Archive Space.',
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

Future<bool> showDoubleConfirmDialog_5(BuildContext context) async {
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
          'Are you sure you want to archive this event activity? You can still view the activity at Archive Space.',
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

Future<bool> showDoubleConfirmDialog_6(BuildContext context) async {
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










