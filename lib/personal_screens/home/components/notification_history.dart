import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/personal_screens/home/components/campaign_detail.dart';
import 'package:mycommunity/personal_screens/home/components/event_detail.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:intl/intl.dart';

class NotificationHistory extends StatefulWidget {
  final String userId;

  NotificationHistory({
    required this.userId,
  });

  @override
  _NotificationHistory createState() => _NotificationHistory();
}

class _NotificationHistory extends State<NotificationHistory> {

  Future<DocumentSnapshot<Map<String, dynamic>>> getActivityDetails(
      String activityId, String activityType) {
    // TODO: Implement the logic to retrieve activity details based on activityId and activityType
    // Replace the code below with your actual implementation
    return FirebaseFirestore.instance
        .collection(activityType == 'campaign' ? 'campaigns' : 'events')
        .doc(activityId)
        .get();
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
          "Notification history",
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.close,
              color: kPrimaryColor,
            ),
            onPressed: () {
              // Call a function to delete all notifications
              showDoubleConfirmDialog(context).then((confirmed) {
                if (confirmed) {
                  deleteAllNotifications(widget.userId);
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
       child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users_data')
              .doc(widget.userId)
              .collection('users_notification')
              .snapshots(),
          builder: (BuildContext context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final notifications = snapshot.data!.docs;
            if (notifications.isEmpty) {
              return const Center(
                child: Text(
                  "Currently you have no notification.",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Raleway',
                    color: mainTextColor,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: notifications.length,
              itemBuilder: (BuildContext context, int index) {
                final notificationData = notifications[index].data();
                final activityId = notifications[index].id;
                final activityType = notificationData['activityType'];
                final notificationDescription = notificationData['geofenceDescription'];
                DateTime notifiedAt = notificationData['notifiedAt'].toDate();

                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: getActivityDetails(activityId, activityType),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                      activitySnapshot) {
                    if (activitySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox();
                    }

                    if (activitySnapshot.hasError) {
                      return Text('Error: ${activitySnapshot.error}');
                    }

                    final activityData = activitySnapshot.data!.data();

                    if (activityData == null || !activitySnapshot.data!.exists) {
                      return const SizedBox();
                    }

                    final activityImage = activityData['image_url'];
                    final activityTitle = activityData['title'];
                    final activityDescription = activityData['description'];

                    return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                                leading: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(
                                      activityImage),
                                ),
                                title: Text(
                                        activityTitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 14,
                                            fontFamily: 'Raleway',
                                            color: mainTextColor,
                                            fontWeight: FontWeight.bold)
                                    ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 5),
                                    Text(
                                        notificationDescription,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13,
                                            fontFamily: 'SourceSansPro',
                                            color: mainTextColor)
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                        'Notification received at: ${DateFormat(
                                            'dd/MM hh:mm a').format(
                                            notifiedAt)}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13,
                                            fontFamily: 'SourceSansPro',
                                            color: mainTextColor)
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.navigate_next_rounded,
                                    size: 30,
                                    color: kPrimaryColor,
                                  ),
                                  onPressed: () {
                                    switch(activityType){
                                      case 'event':
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: activityId)));

                                        break;
                                      case 'campaign':
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: activityId)));
                                        break;
                                    }
                                  },
                                ),
                              ),
                            SizedBox(height: 5),
                            const Divider(color: Color(0xFF707070), thickness: 1)
                          ],
                    );
                  },
                );
              },
            );
          },
        ),
       )
    );
  }

  void deleteAllNotifications(String userId) async {
    try {
      // Retrieve the user's notification collection
      CollectionReference notificationCollection = FirebaseFirestore.instance
          .collection('users_data')
          .doc(userId)
          .collection('users_notification');

      // Create a batched write operation
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Get all notification documents in the collection
      QuerySnapshot snapshot = await notificationCollection.get();

      // Add delete operations to the batch for each document
      snapshot.docs.forEach((doc) {
        batch.delete(doc.reference);
      });

      // Commit the batched write operation
      await batch.commit();

      // Show a success message or perform any desired actions after deleting the notifications
      print('All notifications deleted successfully.');
    } catch (e) {
      // Handle any errors that occur during the deletion process
      print('Error deleting notifications: $e');
    }
  }

  Future<bool> showDoubleConfirmDialog(BuildContext context) async {
    bool confirmed = false;
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            'Confirm',
            style: TextStyle(fontFamily: 'Raleway'),
          ),
          content: Text(
            'Are you sure you want to remove all the notification?',
            style: TextStyle(fontFamily: 'Raleway'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Raleway'),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
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

}