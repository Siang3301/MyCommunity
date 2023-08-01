import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mycommunity/personal_screens/activity/model/event.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/map_screen.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/edit_event_3.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/rounded_address_field.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/rounded_location_link_field.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/rounded_voluteering_detail_field.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/personal_screens/activity/components/edit_event/background_2.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class EditEvent2 extends StatefulWidget{
  final String eventID, title, description, category, volunteer;
  final DateTime dateTimeStart, dateTimeEnd;
  final File? image;
  final Event event;

  EditEvent2({Key? key, required this.eventID, required this.title, required this.description, required this.category, required this.dateTimeStart, required this.dateTimeEnd,
    required this.volunteer, required this.image, required this.event}) : super(key: key);

  @override
  _EditEvent2 createState() => _EditEvent2();
}

class _EditEvent2 extends State<EditEvent2> {
  final _formKey = GlobalKey<FormState>();
  String address = "", locationLink = "", volunteeringDetail = "";
  late Event _event;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    address = widget.event.address;
    locationLink = widget.event.locationLink;
    volunteeringDetail = widget.event.volunteeringDetail;
    _selectedLocation = LatLng(widget.event.selectedLocation.latitude, widget.event.selectedLocation.longitude);
  }

  void _onLocationSelected(LatLng location) {
    setState(() {
      _selectedLocation = location;
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
        backgroundColor: Colors.white,
        bottomOpacity: 0.0,
        elevation: 0.0,
        centerTitle: true,
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
                          child : Text("Step 2 of 3: Additional details", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway")),
                        ),
                        SizedBox(height: size.height * 0.03),
                        RoundedAddressField(
                          onChanged: (value) {
                            setState(() {
                              address = value;
                            });
                          },
                          initialValue: address,
                        ),
                        RoundedLocationLinkField(
                          onChanged: (value) {
                            setState(() {
                              locationLink = value;
                            });
                          },
                          initialValue: locationLink,
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 15),
                          child: const Text("Mark Your Location*", style: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro", fontSize: 15)),
                        ),
                        MapScreen(onLocationSelected: _onLocationSelected, initialLocation: _selectedLocation!),
                        RoundedDetailField(
                          onChanged: (value) {
                            setState(() {
                              volunteeringDetail = value;
                            });
                          }, initialValue: volunteeringDetail
                        ),
                        SizedBox(
                          height: size.height*0.04,
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
                                  if (_formKey.currentState!.validate() && address != "" && _selectedLocation != null) {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateEvent(title: widget.title, description: widget.description, image: widget.image,
                                        category: widget.category, volunteer: widget.volunteer, dateTimeStart: widget.dateTimeStart, dateTimeEnd: widget.dateTimeEnd, address: address, locationLink: locationLink,
                                        selectedLocation: _selectedLocation!, volunteeringDetail: volunteeringDetail, event: widget.event, eventID: widget.eventID)));
                                  } else {
                                    Fluttertoast.showToast(
                                      backgroundColor: Colors.grey,
                                      msg: "You must mark the location before you can advertising your event.",
                                      gravity: ToastGravity.CENTER,
                                      fontSize: 16.0,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor
                                ),
                                child: const Text(
                                  "NEXT", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
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
}





