import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mycommunity/personal_screens/home/components/event/create_event_2.dart';
import 'package:mycommunity/personal_screens/home/components/event/map_screen.dart';
import 'package:mycommunity/personal_screens/home/components/event/rounded_category_field.dart';
import 'package:mycommunity/personal_screens/home/components/event/rounded_date_field.dart';
import 'package:mycommunity/personal_screens/home/components/event/rounded_description_field.dart';
import 'package:mycommunity/personal_screens/home/components/event/rounded_image_field.dart';
import 'package:mycommunity/personal_screens/home/components/event/rounded_time_field.dart';
import 'package:mycommunity/personal_screens/home/components/event/rounded_title_field.dart';
import 'package:mycommunity/personal_screens/home/components/event/rounded_volunteer_field.dart';
import 'package:mycommunity/personal_screens/profile/components/account_management.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/personal_screens/home/components/event/background.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';


class CreateEvent extends StatefulWidget{
  const CreateEvent({Key? key}) : super(key: key);

  @override
  _CreateEvent createState() => _CreateEvent();
}

class _CreateEvent extends State<CreateEvent> {
  final _formKey = GlobalKey<FormState>();
  String title = "", description = "", category = "", volunteer = "";
  DateTime? dateTimeStart, dateTimeEnd;
  File? _selectedImage;
  DateTimeRange? dateRange;
  TimePickerWidget? startTimePicker, endTimePicker;
  TimeOfDay? startTime, endTime;
  RoundedDateField? dateField;

  void _handleDateRangeSelected(DateTimeRange range) {
    setState(() {
      dateRange = range;
    });
    if (dateRange != null){
      dateTimeStart = dateRange!.start;
      dateTimeEnd = dateRange!.end;
    }
    if (startTime != null){
      dateTimeStart = dateTimeStart!.add(Duration(hours: startTime!.hour, minutes: startTime!.minute));
    }
    if (endTime != null){
      dateTimeEnd = dateTimeEnd!.add(Duration(hours: endTime!.hour, minutes: endTime!.minute));
    }
  }

  void _handleStartTimeSelected(TimeOfDay time) {
    // if user reset the time, year month day remains but hours and minutes set to 0.
    dateTimeStart = DateTime(dateTimeStart!.year, dateTimeStart!.month, dateTimeStart!.day, 0, 0, 0);
    setState(() {
      startTime = time;
    });
    if (time != null){
      dateTimeStart = dateTimeStart!.add(Duration(hours: startTime!.hour, minutes: startTime!.minute));
    }
  }

  void _handleEndTimeSelected(TimeOfDay time) {
    // if user reset the time, year month day remains but hours and minutes set to 0.
    dateTimeEnd = DateTime(dateTimeEnd!.year, dateTimeEnd!.month, dateTimeEnd!.day, 0, 0, 0);
    setState(() {
      endTime = time;
    });
    if (time != null){
      dateTimeEnd = dateTimeEnd!.add(Duration(hours: endTime!.hour, minutes: endTime!.minute));
    }
  }

  void _handleCategorySelected(String cat) {
    setState(() {
      category = cat;
    });
  }

  void _onImageSelected(File? image) {
    setState(() {
      _selectedImage = image;
    });
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
          backgroundColor: Colors.white,
          bottomOpacity: 0.0,
          elevation: 0.0,
          centerTitle: true,
          title: const Text("Create Event", style: TextStyle(fontFamily: 'Raleway', fontSize: 18, color: kPrimaryColor, fontWeight: FontWeight.bold)),
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
                        const Text("-New Event-", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway", color: mainTextColor)),
                        SizedBox(height: size.height * 0.03),
                        const Text("To create your event, you should enter the information that required by MyCommunity for promotion in your area.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        SizedBox(height: size.height * 0.03),
                        const Center(
                          child : Text("Step 1 of 3: Event details", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway")),
                        ),
                        SizedBox(height: size.height * 0.03),
                        Center(
                          child : RoundedTitleField(
                            onChanged: (value) {
                              setState(() {
                                title = value.trim();
                              });
                            },
                          )
                        ),
                        Center(
                          child : RoundedDescriptionField(
                            onChanged: (value) {
                              setState(() {
                                description = value.trim();
                              });
                            },
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
                              ),
                            ),
                            SizedBox(
                              width: size.width*0.40,
                              child:RoundedCategoryField(onCategorySelected: _handleCategorySelected)
                            )
                          ],
                         ),
                        Container(
                          padding: const EdgeInsets.only(left: 20, bottom: 10),
                          child: const Text("Image (png or jpg)", style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        ),
                        RoundedImageField(onImageSelected: _onImageSelected),
                        SizedBox(height: size.height * 0.04),
                        Container(
                          padding: const EdgeInsets.only(left: 20, bottom: 10),
                          child: const Text("Date*", style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        ),
                        RoundedDateField(
                            onDateRangeSelected: _handleDateRangeSelected,
                        ),
                        SizedBox(height: size.height * 0.04),
                        Container(
                          padding: const EdgeInsets.only(left: 20, bottom: 10),
                          child: const Text("Time*", style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children:[
                              TimePickerWidget(onTimeSelected: _handleStartTimeSelected),
                              const Icon(Icons.arrow_forward, color: softTextColor),
                              TimePickerWidget(onTimeSelected: _handleEndTimeSelected),
                            ]
                        ),
                        SizedBox(height: size.height * 0.04),
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
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEvent_2(title: title, description: description, dateTimeEnd: dateTimeEnd!,
                                          dateTimeStart: dateTimeStart!, category: category, volunteer: volunteer, image: null)));
                                    }else{
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEvent_2(title: title, description: description, dateTimeEnd: dateTimeEnd!,
                                          dateTimeStart: dateTimeStart!, category: category, volunteer: volunteer, image: _selectedImage)));
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
                                    msg: "You must assign the details with (*) marked, date and time to the event.",
                                    gravity: ToastGravity.CENTER,
                                    fontSize: 16.0,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "PROCEED", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
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
}





