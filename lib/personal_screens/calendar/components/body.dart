import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/organisation_screens/profile/model/user.dart';
import 'package:mycommunity/personal_screens/activity/model/activity.dart';
import 'package:mycommunity/personal_screens/home/components/campaign_detail.dart';
import 'package:mycommunity/personal_screens/home/components/event_detail.dart';
import 'package:mycommunity/personal_screens/home/components/model/campaign_all.dart';
import 'package:mycommunity/personal_screens/home/components/model/event_all.dart';
import 'package:mycommunity/personal_screens/profile/components/account_management.dart';
import 'package:mycommunity/personal_screens/profile/model/user.dart';
import 'package:mycommunity/personal_screens/profile/profile_preview.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/personal_screens/calendar/components/background.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class PersonalCalendarBody extends StatefulWidget{
  const PersonalCalendarBody({Key? key}) : super(key: key);

  @override
  _PersonalCalendarBody createState() => _PersonalCalendarBody();
}

class _PersonalCalendarBody extends State<PersonalCalendarBody> {
  final _formKey = GlobalKey<FormState>();
  // Define variables for the calendar
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day
  );
  DateTime _firstDay = DateTime.utc(DateTime.now().year - 10, 1, 1);
  DateTime _lastDay = DateTime.utc(DateTime.now().year + 10, 12, 31);

  // Define a Map to hold the marked dates
  Map<DateTime, List<dynamic>> _markedDateMap = {}; // Define the events Map
  List<dynamic> _selectedEvents = [];


  Map<DateTime, List<dynamic>> _groupEvents(List<Activity> activity) {
    Map<DateTime, List<dynamic>> data = {};
    activity.forEach((activity) {
      DateTime date =
      DateTime.utc(activity.date_time_start!.year, activity.date_time_start!.month, activity.date_time_start!.day, 12);
      if (data[date] == null) data[date] = [];
      data[date]!.add(activity);
    });
    return data;
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
          if (eventData != null && eventData.dateTimeStart != null) {
            activity.date_time_start = eventData.dateTimeStart;
            activity.date_time_end = eventData.dateTimeEnd;
            activity.name = eventData.title;
            activity.description = eventData.description;
            activity.organizerID = eventData.organizerID;
            activity.activityStatus = eventData.isCompleted;
            activity.joinedUserIds = eventData.joinedUserIds;

            final organizerDoc = await FirebaseFirestore.instance
                .collection('users_data')
                .doc(eventData.organizerID)
                .get();
            final organizerData = Personal.fromFirestore(organizerDoc);
            if (organizerData != null) {
              activity.organizerName = organizerData.name;
            }

            final joinedUser = activity.joinedUserIds?.firstWhere(
                  (user) => user['userId'] == auth.getCurrentUID(),
              orElse: () => null,
            );
            if (joinedUser != null) {
              activity.isArchived = joinedUser['is_archived'];
            }

            if (activity.isArchived == false) {
              currentActivities.add(activity);
            }
          }
        } else if (activity.type == ActivityType.campaign) {
          final campaignDoc = await FirebaseFirestore.instance
              .collection('campaigns')
              .doc(activity.id)
              .get();
          final campaignData = Campaign.fromFirestore(campaignDoc);
          if (campaignData != null && campaignData.dateTimeStart != null) {
            activity.date_time_start = campaignData.dateTimeStart;
            activity.date_time_end = campaignData.dateTimeEnd;
            activity.name = campaignData.title;
            activity.description = campaignData.description;
            activity.organizerID = campaignData.organizerID;
            activity.activityStatus = campaignData.isCompleted;
            activity.joinedUserIds = campaignData.joinedUserIds;

            final organizerDoc = await FirebaseFirestore.instance
                .collection('users_data')
                .doc(campaignData.organizerID)
                .get();
            final organizerData = Organisation.fromFirestore(organizerDoc);
            if (organizerData != null) {
              activity.organizerName = organizerData.orgName;
            }

            final joinedUser = activity.joinedUserIds?.firstWhere(
                  (user) => user['userId'] == auth.getCurrentUID(),
              orElse: () => null,
            );
            if (joinedUser != null) {
              activity.isArchived = joinedUser['is_archived'];
            }

            if (activity.isArchived == false) {
              currentActivities.add(activity);
            }
          }
        }
      }

      currentActivities.sort((a, b) =>
          a.date_time_start!.compareTo(b.date_time_start!));

      return currentActivities;
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    if (_markedDateMap.containsKey(day)) {
      return [_markedDateMap[day]!];
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        backgroundColor: mainBackColor,
        appBar : AppBar(
          centerTitle: false,
          title: Text("Calendar & Schedule", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
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
      body: Background(
          child: SingleChildScrollView(
            child: SafeArea(
              child: StreamBuilder<List<Activity>>(
                stream: getSortedActivitiesStream(context),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox(height:size.height, child:Center(child:CircularProgressIndicator()));
                  }

                  // Clear the existing marked dates
                  _markedDateMap = {};

                 // Add the current activities to the marked dates Map
                  for (final activity in snapshot.data!) {
                    // Check if the activity has a start date
                    if (activity.date_time_start != null) {
                      // Get the start date and end date of the activity
                      final activityStartDate = DateTime.utc(
                        activity.date_time_start!.year,
                        activity.date_time_start!.month,
                        activity.date_time_start!.day,
                      );
                      final activityEndDate = DateTime.utc(
                        activity.date_time_end!.year,
                        activity.date_time_end!.month,
                        activity.date_time_end!.day,
                      );

                      // Loop through all dates between the start and end date of the activity
                      for (var date = activityStartDate; date.isBefore(activityEndDate.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
                        // Check if the date is already in the Map, if not add it
                        if (!_markedDateMap.containsKey(date)) {
                          _markedDateMap[date] = [];
                        }

                        // Add the activity to the list of events for the date
                        _markedDateMap[date]!.add(activity);
                        _markedDateMap[date]!.forEach((activity) {
                          print(activity.date_time_start);
                        });
                      }
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      Padding(
                          padding: const EdgeInsets.only(top:5, left:20, right: 20, bottom: 10),
                          child: TableCalendar(
                            eventLoader: _getEventsForDay,
                            calendarFormat: _calendarFormat,
                            availableCalendarFormats: const {
                              CalendarFormat.month: '2 weeks',
                              CalendarFormat.week: 'Month',
                              CalendarFormat.twoWeeks: 'Week'
                            },
                            focusedDay: _focusedDay,
                            firstDay: _firstDay,
                            lastDay: _lastDay,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            onDaySelected: (selectedDay,focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                                print(_selectedDay);
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            calendarStyle: const CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: kPrimaryColor,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Color(0xFFF5D700),
                                shape: BoxShape.circle,
                              ),
                              selectedTextStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                color: Color(0xFF161D6F),
                              ),
                              defaultTextStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                color: Color(0xFF161D6F),
                              ),
                              weekendTextStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                color: Color(0xFF161D6F),
                              ),
                              outsideTextStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                              holidayTextStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                color: Color(0xFF161D6F),
                              ),
                            ),
                            daysOfWeekStyle: const DaysOfWeekStyle(
                              weekendStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor, // change the color as desired
                              ),
                              weekdayStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF161D6F),// change the color as desired
                              ),
                            ),
                            headerStyle: HeaderStyle(
                              titleCentered: true,
                              titleTextStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Color(0xFF161D6F),
                              ),
                              formatButtonDecoration: BoxDecoration(
                                color: kPrimaryColor,
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              formatButtonTextStyle: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                              ),
                              leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF161D6F)),
                              rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF161D6F)),
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                final children = <Widget>[];
                                if (_markedDateMap[date] != null && _markedDateMap[date]!.isNotEmpty) {
                                  _markedDateMap[date]!.forEach((activity) {
                                    if (activity.activityStatus == true) {
                                      children.add(
                                        Positioned(
                                          left: 20,
                                          bottom: 5,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.green,
                                            ),
                                            width: 10.0,
                                            height: 10.0,
                                          ),
                                        ),
                                      );
                                    }else{
                                      children.add(
                                        Positioned(
                                          left: 20,
                                          bottom: 5,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF161D6F),
                                            ),
                                            width: 10.0,
                                            height: 10.0,
                                          ),
                                        ),
                                      );
                                    }
                                  });
                                }
                                return Stack(
                                  children: children,
                                );
                              },
                            ),
                          ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left:20, right: 20),
                        alignment: Alignment.center,
                        child: _selectedDay != null
                            ? Column(
                          children: [
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Ongoing activities",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Raleway'),
                                ),
                                Text(
                                  DateFormat('EEEE, d MMMM y').format(_selectedDay),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _markedDateMap[_selectedDay]?.isNotEmpty ?? false
                                ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: _markedDateMap[_selectedDay]?.length ?? 0,
                              itemBuilder: (context, index) {
                                final activity = _markedDateMap[_selectedDay]![index];
                                return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                    child: GestureDetector(
                                      onTap: (){
                                        if(activity.type == ActivityType.campaign){
                                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: activity.id)));
                                        }else{
                                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: activity.id)));
                                        }
                                      },
                                      child: Card(
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  SizedBox(
                                                    width: size.width*0.4,
                                                    child: Text(
                                                      activity.name,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Raleway', color: kPrimaryColor),
                                                    )
                                                  ),
                                                  SizedBox(
                                                    width: size.width*0.3,
                                                    child: Text(
                                                      activity.date_time_end != null && activity.date_time_end!.difference(activity.date_time_start!).inDays > 0
                                                          ? DateFormat('dd/MM').format(activity.date_time_start!) + ' - ' + DateFormat('dd/MM').format(activity.date_time_end!)
                                                          : DateFormat('dd/MM \n hh:mm a').format(activity.date_time_start!),
                                                      textAlign: TextAlign.right,
                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: 'Raleway', color: kPrimaryColor),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  SizedBox(
                                                    width: size.width*0.4,
                                                    child:Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          activity.description,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: 'SourceSansPro', color: descColor),
                                                        ),
                                                        SizedBox(height: 10),
                                                        activity.activityStatus == true ?
                                                        const Text(
                                                          "Status: Completed",
                                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: 'Raleway', color: Colors.green),
                                                        ):
                                                        const Text(
                                                          "Status: Running",
                                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: 'Raleway', color: descColor),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: size.width *0.3,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(
                                                          activity.type == ActivityType.campaign ?
                                                          "Organisation: " + activity.organizerName
                                                              : "Person: " + activity.organizerName,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          textAlign: TextAlign.end,
                                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: 'Raleway', color: kPrimaryColor),
                                                        ),
                                                        SizedBox(height: 10),
                                                        Text(
                                                          activity.type == ActivityType.campaign ?
                                                          "Type: Campaign"
                                                              : "Type: Event",
                                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, fontFamily: 'Raleway', color: kPrimaryColor),
                                                        )
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                );
                              },
                            )
                                : const Padding(padding: EdgeInsets.only(top:50),child:Text(
                                  "You have no activity today, cheers!",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: kPrimaryColor),
                                )),
                          ],
                        )
                            : Container(),
                      )
                    ],
                  );
                },
              )
            )
          ),
        )
    );
  }
}
