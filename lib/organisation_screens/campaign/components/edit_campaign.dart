import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mycommunity/organisation_screens/campaign/components/edit_campaign_2.dart';
import 'package:mycommunity/organisation_screens/campaign/model/campaign.dart';
import 'package:mycommunity/organisation_screens/home/components/create_campaign.dart';
import 'package:mycommunity/organisation_screens/campaign/components/rounded_category_field.dart';
import 'package:mycommunity/organisation_screens/campaign/components/rounded_date_field.dart';
import 'package:mycommunity/organisation_screens/campaign/components/rounded_description_field.dart';
import 'package:mycommunity/organisation_screens/campaign/components/rounded_image_field.dart';
import 'package:mycommunity/organisation_screens/campaign/components/rounded_time_field.dart';
import 'package:mycommunity/organisation_screens/campaign/components/rounded_title_field.dart';
import 'package:mycommunity/organisation_screens/campaign/components/rounded_volunteer_field.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart' as smtp;
import 'package:mycommunity/organisation_screens/campaign/components/background_2.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';


class EditCampaign extends StatefulWidget{
  final String campaignID;

  const EditCampaign({Key? key, required this.campaignID}) : super(key: key);
  @override
  _EditCampaign createState() => _EditCampaign();
}

class _EditCampaign extends State<EditCampaign> {
  late Future<Campaign?> _futureCampaign;

  @override
  void initState() {
    super.initState();
    _futureCampaign = getCampaignData(widget.campaignID);
  }

  Future<Campaign?> getCampaignData(String campaignID) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('campaigns')
          .doc(campaignID)
          .get();

      if (doc.exists) {
        Campaign campaign = Campaign.fromFirestore(doc);
        return campaign;
      } else {
        return null;
      }
    } catch (e) {
      print('Error retrieving campaign data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Campaign?>(
        future: _futureCampaign,
        builder: (BuildContext context, AsyncSnapshot<Campaign?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return EditCampaignInterface(initialCampaign: snapshot.data!, campaignID: widget.campaignID);
          }
        },
      ),
    );
  }

}


class EditCampaignInterface extends StatefulWidget {
  final Campaign initialCampaign;
  final String campaignID;

  EditCampaignInterface({required this.initialCampaign, required this.campaignID});

  @override
  _EditCampaignInterface createState() => _EditCampaignInterface();
}

class _EditCampaignInterface extends State<EditCampaignInterface> {
  final _formKey = GlobalKey<FormState>();
  String title = "", description = "", category = "Technology", volunteer = "", imageUrl = "", organizerName = "";
  DateTime? dateTimeStart = DateTime.now(), dateTimeEnd = DateTime.now();
  File? _selectedImage;
  DateTimeRange? dateRange;
  TimePickerWidget? startTimePicker, endTimePicker;
  TimeOfDay? startTime, endTime;
  late Campaign _campaign;

  @override
  void initState() {
    super.initState();
    _campaign = widget.initialCampaign;
    title = _campaign.title;
    description = _campaign.description;
    volunteer = _campaign.volunteer;
    category = _campaign.category;
    imageUrl = _campaign.imageUrl;
    dateTimeStart = _campaign.dateTimeStart;
    dateTimeEnd = _campaign.dateTimeEnd;
    startTime = TimeOfDay(hour: _campaign.dateTimeStart.hour, minute: _campaign.dateTimeStart.minute);
    endTime = TimeOfDay(hour: _campaign.dateTimeEnd.hour, minute: _campaign.dateTimeEnd.minute);
  }

  void _handleDateRangeSelected(DateTimeRange range) {
    setState(() {
      dateRange = range;
    });
    if (dateRange != null){
      dateTimeStart = dateRange?.start;
      dateTimeEnd = dateRange?.end;
    }
    if (startTime != null){
      dateTimeStart = dateTimeStart?.add(Duration(hours: startTime!.hour, minutes: startTime!.minute));
    }
    if (endTime != null){
      dateTimeEnd = dateTimeEnd?.add(Duration(hours: endTime!.hour, minutes: endTime!.minute));
    }
  }

  void _handleStartTimeSelected(TimeOfDay time) {
    // if user reset the time, year month day remains but hours and minutes set to 0.
    dateTimeStart = DateTime(dateTimeStart!.year, dateTimeStart!.month, dateTimeStart!.day, 0, 0, 0);
    setState(() {
      startTime = time;
    });
    if (time != null){
      dateTimeStart = dateTimeStart?.add(Duration(hours: startTime!.hour, minutes: startTime!.minute));
    }
  }

  void _handleEndTimeSelected(TimeOfDay time) {
    // if user reset the time, year month day remains but hours and minutes set to 0.
    dateTimeEnd = DateTime(dateTimeEnd!.year, dateTimeEnd!.month, dateTimeEnd!.day, 0, 0, 0);
    setState(() {
      endTime = time;
    });
    if (time != null){
      dateTimeEnd = dateTimeEnd?.add(Duration(hours: endTime!.hour, minutes: endTime!.minute));
    }
  }

  void _handleCategorySelected(String cat) {
    setState(() {
      category = cat;
    });
  }

  void _onImageSelected(File? image) {
    setState(() {
      _selectedImage = image!;
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
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home_2',
                            (route) => false,
                        arguments: {'tabIndex': currentIndex},
                      );
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
    final username = auth.getUser()!.displayName as String;

    return Scaffold(
        backgroundColor: mainBackColor,
        appBar : AppBar(
          leading: const BackButton(color: kPrimaryColor),
          centerTitle: true,
          title:  const Text("Edit Campaign", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
          backgroundColor: Colors.white,
          bottomOpacity: 0.0,
          elevation: 0.0,
        ),
        body:  Form(
            key: _formKey,
            child: Background(
              child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("-Edit Campaign-", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway", color: mainTextColor)),
                            Container(
                              alignment: Alignment.centerRight,
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
                                    backgroundColor: orgMainColor
                                ),
                                child: const Text(
                                  "COMPLETE", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.03),
                        const Text("To edit your commission, you should enter the information that required by MyCommunity for promotion in your area.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        SizedBox(height: size.height * 0.03),
                        const Center(
                          child : Text("Step 1 of 3: Campaign details", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway")),
                        ),
                        SizedBox(height: size.height * 0.03),
                        Center(
                            child : RoundedTitleField(
                              onChanged: (value) {
                                setState(() {
                                  title = value.trim();
                                });
                              },
                              initialValue: title,
                            )
                        ),
                        Center(
                            child : RoundedDescriptionField(
                              onChanged: (value) {
                                setState(() {
                                  description = value.trim();
                                });
                              },
                              initialValue: description,
                            )
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: size.width*0.40,
                              child:RoundedVolunteerField(
                                  onChanged: (value) {
                                    setState(() {
                                      volunteer = value;
                                    });
                                  },
                                  initialValue: volunteer
                              ),
                            ),
                            SizedBox(
                                width: size.width*0.40,
                                child:RoundedCategoryField(onCategorySelected: _handleCategorySelected, initialValue: category)
                            )
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 20, bottom: 10),
                          child: const Text("Image (png or jpg)", style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        ),
                        RoundedImageField(onImageSelected: _onImageSelected, imageUrl: imageUrl),
                        SizedBox(height: size.height * 0.04),
                        Container(
                          padding: const EdgeInsets.only(left: 20, bottom: 10),
                          child: const Text("Date*", style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        ),
                        RoundedDateField(
                          onDateRangeSelected: _handleDateRangeSelected, initialDateTimeStart: dateTimeStart!, initialDateTimeEnd: dateTimeEnd!,
                        ),
                        SizedBox(height: size.height * 0.04),
                        Container(
                          padding: const EdgeInsets.only(left: 20, bottom: 10),
                          child: const Text("Time*", style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children:[
                              TimePickerWidget(onTimeSelected: _handleStartTimeSelected, initialTime: TimeOfDay(hour: startTime!.hour, minute: startTime!.minute)),
                              const Icon(Icons.arrow_forward, color: softTextColor),
                              TimePickerWidget(onTimeSelected: _handleEndTimeSelected, initialTime: TimeOfDay(hour: endTime!.hour, minute: endTime!.minute)),
                            ]
                        ),
                        SizedBox(height: size.height * 0.04),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children:[
                              Container(
                                  alignment: Alignment.center,
                                  width: size.width * 0.50,
                                  height: size.height * 0.06,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child:ElevatedButton(
                                    onPressed: ()  {
                                      if (widget.campaignID != "") {
                                        _deleteCampaign(context, widget.campaignID, _campaign.organizerID, _campaign.title, _campaign.joinedUserIds);
                                      } else {
                                        Fluttertoast.showToast(
                                          backgroundColor: Colors.grey,
                                          msg: "Campaign cannot be deleted.",
                                          gravity: ToastGravity.CENTER,
                                          fontSize: 16.0,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: orgMainColor
                                    ),
                                    child: const Text(
                                      "DELETE CAMPAIGN", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                                    ),
                                  )
                              ),
                              Container(
                                  alignment: Alignment.center,
                                  width: size.width * 0.25,
                                  height: size.height * 0.06,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child:ElevatedButton(
                                    onPressed: ()  {
                                      if (_formKey.currentState!.validate() && startTime != null && endTime != null && dateTimeStart != null && dateTimeEnd != null) {
                                        //Check time, should more than 30 minutes!
                                        int startMinutes = startTime!.hour * 60 + startTime!.minute;
                                        int endMinutes = endTime!.hour * 60 + endTime!.minute;
                                        int minuteDifference = endMinutes - startMinutes;
                                        if (minuteDifference < 30) {
                                          Fluttertoast.showToast(
                                            backgroundColor: Colors.grey,
                                            msg: "Your activity should be at least 30 minutes!",
                                            gravity: ToastGravity.CENTER,
                                            fontSize: 16.0,
                                          );
                                          return;
                                        }
                                        //Check date, the date time start must be today at least!
                                        DateTime minimumDateTime = dateTimeStart!.add(Duration(minutes: 30));
                                        DateTime currentTime = DateTime.now();
                                        if (minimumDateTime.isAfter(currentTime)) {
                                          if(_selectedImage == null){
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => EditCampaign2(title: title, description: description, dateTimeEnd: dateTimeEnd!,
                                                dateTimeStart: dateTimeStart!, category: category, volunteer: volunteer, image: null, campaign: _campaign, campaignID: widget.campaignID)));
                                          }else{
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => EditCampaign2(title: title, description: description, dateTimeEnd: dateTimeEnd!,
                                                dateTimeStart: dateTimeStart!, category: category, volunteer: volunteer, image: _selectedImage, campaign: _campaign, campaignID: widget.campaignID)));
                                          }
                                          print("valid input");
                                        } else {
                                          Fluttertoast.showToast(
                                            backgroundColor: Colors.grey,
                                            msg: "Your activity must be in future!",
                                            gravity: ToastGravity.CENTER,
                                            fontSize: 16.0,
                                          );
                                          return;
                                        }
                                      } else {
                                        Fluttertoast.showToast(
                                          backgroundColor: Colors.grey,
                                          msg: "You must assign the details with (*) marked, date and time to the campaign.",
                                          gravity: ToastGravity.CENTER,
                                          fontSize: 16.0,
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: orgMainColor
                                    ),
                                    child: const Text(
                                      "NEXT", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                                    ),
                                  )
                              ),                            ]
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


