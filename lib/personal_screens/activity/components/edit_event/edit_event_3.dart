import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mycommunity/personal_screens/activity/model/event.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/map_screen_preview.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/rounded_message_customizationl_field.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/rounded_radius_field.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/background_2.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class UpdateEvent extends StatefulWidget{
  final String eventID, title, description, category, volunteer, address, locationLink, volunteeringDetail;
  final DateTime dateTimeStart, dateTimeEnd;
  final File? image;
  final LatLng selectedLocation;
  final Event event;

  const UpdateEvent({Key? key, required this.eventID, required this.title, required this.description, required this.category, required this.dateTimeStart, required this.dateTimeEnd,
    required this.volunteer, required this.image, required this.address, required this.locationLink, required this.selectedLocation,
    required this.volunteeringDetail, required this.event}) : super(key: key);

  @override
  _UpdateEvent createState() => _UpdateEvent();
}

class _UpdateEvent extends State<UpdateEvent> {
  final _formKey = GlobalKey<FormState>();
  double _geofenceRadius = 0;
  String _message = "";
  late Map<String, dynamic> _mapEventData;
  late UpdateEvent eventData;

  @override
  void initState() {
    super.initState();

    _message = widget.event.message;
    _geofenceRadius = widget.event.geoFenceRadius;

    //Store data
    Map<String, dynamic> _mapEventData = {
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

    eventData = UpdateEvent(
      title: _mapEventData['title'],
      description: _mapEventData['description'],
      category: _mapEventData['category'],
      dateTimeStart: _mapEventData['dateTimeStart'],
      dateTimeEnd: _mapEventData['dateTimeEnd'],
      volunteer: _mapEventData['volunteer'],
      image: widget.image,
      address: _mapEventData['address'],
      locationLink: _mapEventData['locationLink'],
      selectedLocation: _mapEventData['selectedLocation'],
      volunteeringDetail: _mapEventData['volunteeringDetail'],
      eventID: widget.eventID,
      event: widget.event,
    );
  }

  //Upload&Update Event to Database
  Future<void> uploadEvent(BuildContext context, UpdateEvent data, double geoFenceRadius, String message, File? image, String organizerName,
                              String organizerID, String eventID) async {
    String imageUrl = "";

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
                "Updating event...",
                style: TextStyle(fontFamily: 'Raleway'),
              ),
            ],
          ),
        ),
      );

      if(image != null) {
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child(
            "event_images").child("${DateTime
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
            builder: (BuildContext context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: progress),
                  const SizedBox(height: 16),
                  Text(
                    "Updating event...\n${progress.toStringAsFixed(2)}%",
                    style: TextStyle(fontFamily: 'Raleway'),
                  ),
                ],
              ),
            ),
          );
        });
        final TaskSnapshot downloadUrl = (await uploadTask);
        imageUrl = await downloadUrl.ref.getDownloadURL();

        // Update event data to Firestore with image updated
        await FirebaseFirestore.instance.collection("events").doc(eventID).update({
          "title": data.title,
          "description": data.description,
          "category": data.category,
          "date_time_start": data.dateTimeStart,
          "date_time_end": data.dateTimeEnd,
          "maxVolunteers": data.volunteer,
          "image_url": imageUrl,
          "address": data.address,
          "location_link": data.locationLink,
          "selected_location": GeoPoint(data.selectedLocation.latitude, data.selectedLocation.longitude),
          "volunteering_detail": data.volunteeringDetail,
          "message": _message,
          "geofence_radius": geoFenceRadius,
          "organizerID": organizerID
        });
      } else {
        // Update event data to Firestore without image updated
        await FirebaseFirestore.instance.collection("events").doc(eventID).update({
          "title": data.title,
          "description": data.description,
          "category": data.category,
          "date_time_start": data.dateTimeStart,
          "date_time_end": data.dateTimeEnd,
          "maxVolunteers": data.volunteer,
          "address": data.address,
          "location_link": data.locationLink,
          "selected_location": GeoPoint(data.selectedLocation.latitude, data.selectedLocation.longitude),
          "volunteering_detail": data.volunteeringDetail,
          "message": _message,
          "geofence_radius": geoFenceRadius,
          "organizerID": organizerID
        });
      }

      // Hide loading dialog and show success dialog
      Navigator.of(context).pop(); // Dismiss previous dialog

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            "Event updated successfully!",
            style: TextStyle(fontFamily: 'Raleway'),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home_1',
                        (route) => false,
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
            "An error occurred while updating the event: $error",
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;
    final creatorName = auth.getUser()!.displayName as String;
    final creatorID = auth.getCurrentUID();

    return Scaffold(
        backgroundColor: mainBackColor,
        appBar : AppBar(
        leading: const BackButton(color: kPrimaryColor),
        backgroundColor: Colors.white,
        bottomOpacity: 0.0,
        elevation: 0.0,
        title: const Text("Edit Event", style: TextStyle(fontFamily: 'Raleway', fontSize: 18, color: kPrimaryColor, fontWeight: FontWeight.bold)),
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
                        const Text("- Event Location -", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway", color: mainTextColor)),
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
                          initialValue: _geofenceRadius.toString(),
                        ),
                        MapScreenPreview(onLocationSelected : widget.selectedLocation, geoFenceRadius: _geofenceRadius),
                        RoundedMessageField(
                          onChanged: (value) {
                            setState(() {
                              _message = value;
                            });
                          },
                          initialValue: _message,
                        ),
                        Center(
                          child:Container(
                              alignment: Alignment.center,
                              width: size.width * 0.70,
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
                                        uploadEvent(context,
                                            eventData,
                                            _geofenceRadius, _message,
                                            widget.image, creatorName,
                                            creatorID, widget.eventID);
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
                                    backgroundColor: kPrimaryColor
                                ),
                                child: const Text(
                                  "CONFIRM AND SAVE CHANGES", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
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
            'Are you sure you want to publish the event?',
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





