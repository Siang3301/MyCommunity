import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mycommunity/organisation_screens/home/components/map_screen_preview.dart';
import 'package:mycommunity/organisation_screens/home/components/rounded_message_customizationl_field.dart';
import 'package:mycommunity/organisation_screens/home/components/rounded_radius_field.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/organisation_screens/home/components/background_2.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart' as smtp;


class PublishCampaign extends StatefulWidget{
  final String title, description, category, volunteer, address, locationLink, volunteeringDetail;
  final DateTime dateTimeStart, dateTimeEnd;
  final File? image;
  final LatLng selectedLocation;

  const PublishCampaign({Key? key, required this.title, required this.description, required this.category, required this.dateTimeStart, required this.dateTimeEnd,
    required this.volunteer, required this.image, required this.address, required this.locationLink, required this.selectedLocation,
    required this.volunteeringDetail}) : super(key: key);

  @override
  _PublishCampaign createState() => _PublishCampaign();
}

class _PublishCampaign extends State<PublishCampaign> {
  final _formKey = GlobalKey<FormState>();
  double _geofenceRadius = 0;
  String _message = "";
  late Map<String, dynamic>? _mapCampaignData;
  late PublishCampaign? campaignData;

  @override
  void initState() {
    super.initState();
    //Store data
    Map<String, dynamic> _mapCampaignData = {
      "title": widget.title,
      "description": widget.description,
      "category": widget.category,
      "dateTimeStart": widget.dateTimeStart,
      "dateTimeEnd": widget.dateTimeEnd,
      "volunteer": widget.volunteer,
      "address": widget.address,
      "locationLink": widget.locationLink,
      "selectedLocation": widget.selectedLocation,
      "volunteeringDetail": widget.volunteeringDetail,
    };

    campaignData = PublishCampaign(
      title: _mapCampaignData['title'],
      description: _mapCampaignData['description'],
      category: _mapCampaignData['category'],
      dateTimeStart: _mapCampaignData['dateTimeStart'],
      dateTimeEnd: _mapCampaignData['dateTimeEnd'],
      volunteer: _mapCampaignData['volunteer'],
      image: widget.image,
      address: _mapCampaignData['address'],
      locationLink: _mapCampaignData['locationLink'],
      selectedLocation: _mapCampaignData['selectedLocation'],
      volunteeringDetail: _mapCampaignData['volunteeringDetail'],
    );

  }

  //Upload Campaign to Database
  Future<void> uploadCampaign(BuildContext context, PublishCampaign data, double geoFenceRadius, String message, File? image,
                              String organizerName,
                              String organizerID) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Uploading campaign...",
                style: TextStyle(fontFamily: 'Raleway'),
              ),
            ],
          ),
        ),
      );

      String imageUrl = "";
      // Upload image to Firebase Storage
      if(image != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
            "campaign_images").child("${DateTime
            .now()
            .millisecondsSinceEpoch}.jpg");
        final uploadTask = storageRef.putFile(image);
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          // Update loading dialog with upload progress
          double progress = (snapshot.bytesTransferred / snapshot.totalBytes) *
              100;
          Navigator.of(context).pop(); // Dismiss previous dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) =>
                AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(value: progress),
                      const SizedBox(height: 16),
                      Text(
                        "Uploading campaign...\n${progress.toStringAsFixed(
                            2)}%",
                        style: TextStyle(fontFamily: 'Raleway'),
                      ),
                    ],
                  ),
                ),
          );
        });
        final TaskSnapshot downloadUrl = (await uploadTask);
        imageUrl = await downloadUrl.ref.getDownloadURL();
      }else {
        imageUrl =
        "https://firebasestorage.googleapis.com/v0/b/geofencing-community.appspot.com/o/default%2Fe26bb422d8831c71b24fa48025b91e13.jpg?alt=media&token=2356f262-bcb5-4a4f-9064-f0655b89f139";
      }

      // Save campaign data to Firestore
      await FirebaseFirestore.instance.collection("campaigns_review").add({
        "title": data.title,
        "description": data.description,
        "category": data.category,
        "date_time_start": data.dateTimeStart,
        "date_time_end": data.dateTimeEnd,
        "maxVolunteers": data.volunteer,
        "currentVolunteers": "0",
        "image_url": imageUrl,
        "address": data.address,
        "location_link": data.locationLink,
        "selected_location": GeoPoint(data.selectedLocation.latitude, data.selectedLocation.longitude),
        "volunteering_detail": data.volunteeringDetail,
        "message": _message,
        "geofence_radius": geoFenceRadius,
        "organizerID": organizerID,
        "is_completed": false,
        "is_archived": false,
        "is_reviewed": false,
        "is_approved": false,
        'joinedUserIds': FieldValue.arrayUnion([]),
      });

      //sendEmailApproval to admin for fast response
      sendEmailForApproval(data.title, organizerName);

      // Hide loading dialog and show success dialog
      Navigator.of(context).pop(); // Dismiss previous dialog
      currentIndex = 1;
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            "Campaign uploaded successfully! Your campaign will be checked shortly by the management team, you will receive an email notification if your activity is done checking.",
            style: TextStyle(fontFamily: 'Raleway'),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home_2', (route) => false,
                    arguments: {'tabIndex': currentIndex},
                  ),
              child: Text("OK", style: TextStyle(fontFamily: 'Raleway')),
            ),
          ],
        ),
      );
    } catch (error) {
      // Hide loading dialog and show error dialog
      Navigator.of(context).pop(); // Dismiss previous dialog
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            "An error occurred while uploading the campaign: $error",
            style: TextStyle(fontFamily: 'Raleway'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK", style: TextStyle(fontFamily: 'Raleway')),
            ),
          ],
        ),
      );
    }
  }

  void sendEmailForApproval(String activityTitle, String organizerName) async {
    final smtpServer = smtp.gmail('mycommunity.managament@gmail.com', 'qjszowtofbwowdwq');
    // Replace 'your_email_address' with your actual email address and 'your_password' with your email password.

    final emailMessage = mailer.Message()
      ..from = mailer.Address('mycommunity.managament@gmail.com')
      ..recipients.add('mycommunity.managament@gmail.com')
      ..subject = 'New Community Campaign Created by $organizerName'
      ..text =
          'This is a system generated email,\n\nA new community campaign "$activityTitle" has been created by organizer/creator "$organizerName". Please verify and review the activity as soon as possible.\n\nThanks,\nToward make a better community,\nMyCommunity Management Team.'

      ..html = '''
    <p>This is a self-generated email,</p>
    <p>A new community campaign "$activityTitle" has been created by organizer/creator "$organizerName". Please verify and review the activity as soon as possible.</p>
    <p>Thanks,<br>
    Toward make a better community,<br>
    MyCommunity Management Team.</p>
''';

    try {
      final sendReport = await mailer.send(emailMessage, smtpServer);
      print('New community campaign verification email sent: ${sendReport.toString()}');
    } catch (e) {
      print('Error sending cancellation email: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;
    final creatorID = auth.getCurrentUID();
    final creatorName = auth.getUser()!.displayName as String;

    return Scaffold(
        backgroundColor: mainBackColor,
        appBar : AppBar(
        leading: const BackButton(color: kPrimaryColor),
        backgroundColor: Colors.white,
        bottomOpacity: 0.0,
        elevation: 0.0,
        centerTitle: true,
        title: const Text("Create Campaign", style: TextStyle(fontFamily: 'Raleway', fontSize: 18, color: kPrimaryColor, fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: Background(
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text("- Campaign Location -", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway", color: mainTextColor)),
                        SizedBox(height: size.height * 0.03),
                        const Text("This information is required by MyCommunity system for the advertising process.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        SizedBox(height: size.height * 0.03),
                        const Center(
                          child : Text("Step 3 of 3: Advertisement details", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway")),
                        ),
                        SizedBox(height: size.height * 0.03),
                        RoundedRadiusField(
                          onChanged: (value) {
                            setState(() {
                              _geofenceRadius = double.parse(value);
                            });
                          },
                        ),
                        MapScreenPreview(onLocationSelected : widget.selectedLocation, geoFenceRadius: _geofenceRadius),
                        RoundedMessageField(
                          onChanged: (value) {
                            setState(() {
                              _message = value;
                            });
                          },
                        ),
                        Center(
                          child:Container(
                              alignment: Alignment.center,
                              width: size.width * 0.25,
                              height: size.height * 0.06,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                shape: BoxShape.rectangle,
                              ),
                              child:ElevatedButton(
                                onPressed: ()  {
                                  if (_formKey.currentState!.validate() && _geofenceRadius != 0) {
                                      //user to double confirm, then perform the action publish
                                    showDoubleConfirmDialog(context).then((confirmed) {
                                      if (confirmed) {
                                        uploadCampaign(context,
                                            campaignData!,
                                            _geofenceRadius, _message,
                                            widget.image, creatorName,
                                            creatorID);
                                      }
                                    });
                                  } else {
                                    Fluttertoast.showToast(
                                      backgroundColor: Colors.grey,
                                      msg: "You must determine the radius of geofence for advertisement!",
                                      gravity: ToastGravity.CENTER,
                                      fontSize: 16.0,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: orgMainColor
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text(
                                    "PUBLISH", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                                  ),
                                ),
                              )
                          ),
                        )
                      ],
               ),
            )
          ),
        )
     )
    );
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
            'Are you sure you want to publish the campaign?',
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





