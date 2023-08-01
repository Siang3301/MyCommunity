import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/initial_screens/welcome/welcome_screen.dart';
import 'package:mycommunity/personal_screens/profile/activity_archive.dart';
import 'package:mycommunity/personal_screens/profile/components/preferences.dart';
import 'package:mycommunity/personal_screens/profile/model/badge.dart';
import 'package:mycommunity/personal_screens/profile/model/user.dart';
import 'package:mycommunity/personal_screens/profile/profile_preview.dart';
import 'package:mycommunity/services/auth_service.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

String formatDateTime(DateTime dateTime) {
  final formatter = DateFormat('dd MMM yyyy h:mm a');
  String formattedDateTime = formatter.format(dateTime);
  return formattedDateTime;
}

class NavDrawer extends StatefulWidget{
  final String userId;
  const NavDrawer({Key? key, required this.userId}) : super(key: key);

  @override
  _NavDrawer createState() => _NavDrawer();
}

class _NavDrawer extends State<NavDrawer> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;
    int totalVolunteerHours = 0;
    final defaultURL = "https://firebasestorage.googleapis.com/v0/b/geofencing-community.appspot.com/o/default%2FDefault-Account-Icon-03bnfc3-300x300.png?alt=media&token=08320d63-ea83-4e07-8c85-f53c2c01647b";

    return Drawer(
      backgroundColor: mainBackColor,
      child: Padding(
        padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Container(
            height: 275,
            child: DrawerHeader(
                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('users_data')
                      .doc(widget.userId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      Personal user = Personal.fromFirestore(snapshot.data!);
                      Map<String, dynamic>? userData = snapshot.data!.data();
                      user.totalVolunteerHours = userData?['total_volunteer_hours'] ?? 0;
                      totalVolunteerHours = user.totalVolunteerHours;
                      UserBadge badge = getBadge(user.totalVolunteerHours);
                      tz.initializeTimeZones();

                      // Get the creation time in UTC
                      DateTime creationTime = auth.getUser()!.metadata.creationTime!;

                      // Set the timezone to GMT+8
                      tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

                      // Convert the creation time to GMT+8
                      tz.TZDateTime creationTimeGMT8 = tz.TZDateTime.from(creationTime, tz.local);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'MyCommunity',
                              style: TextStyle(color: kSecondaryColor,fontSize: 20, fontFamily: 'Raleway'),
                            ),
                            Container(
                                margin: EdgeInsets.only(top: 15,bottom: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey, width: 1),
                                ),
                                child:CircleAvatar(
                                  radius: 40,
                                  backgroundColor: secBackColor,
                                  backgroundImage: user.imageUrl == "" || user.imageUrl == null || user.imageUrl == "null"
                                      ? CachedNetworkImageProvider("https://firebasestorage.googleapis.com/v0/b/geofencing-community.appspot.com/o/default%2FDefault-Account-Icon-03bnfc3-300x300.png?alt=media&token=08320d63-ea83-4e07-8c85-f53c2c01647b")
                                      : CachedNetworkImageProvider(user.imageUrl),
                                )
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                user.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(color: mainTextColor,fontSize: 16, fontFamily: 'Poppins'),
                              ),
                            ),

                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Joined on ',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: mainTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: formatDateTime(creationTimeGMT8),
                                    style: TextStyle(
                                      color: mainTextColor,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '- ${badge.title} -',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  fontFamily: 'Poppins',
                                  color: kPrimaryColor),
                            )
                          ],
                        );
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      return Container(height: size.height*0.5, alignment: Alignment.center, child:CircularProgressIndicator());
                    }
                  },
                )
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 5),
            child: ListTile(
                leading: Icon(Icons.verified_user),
                title: const Text('Profile', style: TextStyle(fontFamily: 'Poppins', color: mainTextColor)),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => PersonalProfilePreview(userId: widget.userId)));
                }
            ),
          ),
          Container(
              margin: EdgeInsets.only(left: 5),
              child: ListTile(
                leading: Icon(Icons.badge_rounded),
                title: const Text('Community Badge', style: TextStyle(fontFamily: 'Poppins', color: mainTextColor)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return BadgeDialog(totalVolunteerHours: totalVolunteerHours);
                    },
                  );
                },
              ),
          ),
          Container(
              margin: EdgeInsets.only(left: 5),
              child: ListTile(
                leading: Icon(Icons.archive),
                title: const Text('Archive Space', style: TextStyle(fontFamily: 'Poppins', color: mainTextColor)),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ArchiveSpace()));
                },
              )
          ),
          Container(
              margin: EdgeInsets.only(left: 5),
              child: ListTile(
                leading: Icon(Icons.interests_rounded),
                title: const Text('My Preferences', style: TextStyle(fontFamily: 'Poppins', color: mainTextColor)),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => PreferencesManagement(userID: auth.getCurrentUID())));
                },
              )
          ),
          Container(
            margin: EdgeInsets.only(left: 5),
            child: ListTile(
              leading: Icon(Icons.exit_to_app),
              title: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', color: mainTextColor)),
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Dialog(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircularProgressIndicator(),
                            SizedBox(width: 16.0),
                            Text('Logging out...', style: TextStyle(fontFamily: 'Poppins')),
                          ],
                        ),
                      ),
                    );
                  },
                );

                await AuthService.logout();

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (BuildContext context) => WelcomeScreen()),
                  ModalRoute.withName('/'),
                );
              },
            ),
          ),
          Expanded(
            child: Container (
                alignment: Alignment.bottomLeft,
                padding: EdgeInsets.only(left:15, bottom:25),
                child: const Text("Developed by Chen Zhun Siang", style: TextStyle(fontFamily: 'Raleway', color: mainTextColor))
            ),
          )
        ],
       ),
      )
    );
  }
}