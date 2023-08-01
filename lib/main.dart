import 'dart:async';
import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geofence_service/geofence_service.dart';
import 'package:get/get.dart';
import 'package:mycommunity/initial_screens/Login/login_screen.dart';
import 'package:mycommunity/initial_screens/onboarding_screen.dart';
import 'package:mycommunity/initial_screens/signup/signup_screen.dart';
import 'package:mycommunity/initial_screens/welcome/welcome_screen.dart';
import 'package:mycommunity/organisation_screens/campaign/organisation_campaign.dart';
import 'package:mycommunity/organisation_screens/home/organisation_home.dart';
import 'package:mycommunity/organisation_screens/profile/organisation_profile.dart';
import 'package:mycommunity/organisation_screens/statistics/campaign_statistics.dart';
import 'package:mycommunity/personal_screens/activity/personal_activity.dart';
import 'package:mycommunity/personal_screens/calendar/personal_calendar.dart';
import 'package:mycommunity/personal_screens/home/components/campaign_detail.dart';
import 'package:mycommunity/personal_screens/home/components/event/create_event.dart';
import 'package:mycommunity/personal_screens/home/components/event_detail.dart';
import 'package:mycommunity/personal_screens/home/personal_home.dart';
import 'package:mycommunity/personal_screens/profile/personal_profile.dart';
import 'package:mycommunity/services/auth_service.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/services/dynamic_link.dart';
import 'package:mycommunity/services/geofencing_service.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart' as lc;

bool _seenOnboarding = false;

Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  _seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('campaign');
  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  AwesomeNotifications().initialize(
    // Initialize the package with your desired settings
    'resource://drawable/campaign',
    [
      NotificationChannel(
        channelKey: 'MyCampaigns',
        channelName: 'MyCampaigns',
        defaultColor: kPrimaryColor,
        ledColor: kPrimaryColor,
        channelDescription: 'Exploring the community campaigns around you!',
        channelShowBadge: true,
        importance: NotificationImportance.High,
        enableVibration: true,
      ),
      NotificationChannel(
        channelKey: 'MyEvents',
        channelName: 'MyEvents',
        defaultColor: kPrimaryColor,
        ledColor: kPrimaryColor,
        channelDescription: 'Exploring the community events around you!',
        channelShowBadge: true,
        importance: NotificationImportance.High,
        enableVibration: true,
      ),
    ],
  );
  AwesomeNotifications().actionStream.listen((receivedNotification) {
    if (receivedNotification.channelKey == 'MyCampaigns') {
      final payloadString = jsonEncode(receivedNotification.payload);
      final decodedPayload = jsonDecode(payloadString);
      final campaignId = decodedPayload['campaignId'];
      navigateToCampaignDetail(campaignId);
    } else {
      final payloadString = jsonEncode(receivedNotification.payload);
      final decodedPayload = jsonDecode(payloadString);
      final eventId = decodedPayload['eventId'];
      navigateToEventDetail(eventId);
    }
  });
  await Firebase.initializeApp(options: const FirebaseOptions(
      apiKey: "AIzaSyA5UcqQw80X56pLYF8RHeEhIh7mxBcWj7g", appId: "1:680745509303:android:b42bd8f17b6c61eaf14832",
      messagingSenderId: "680745509303", projectId: "geofencing-community", storageBucket: "gs://geofencing-community.appspot.com"));

  runApp(MyCommunity());
}

Future<dynamic> navigateToEventDetail(String eventId) {
  return GlobalVariable.navState.currentState!.push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: eventId)));
}

Future<dynamic> navigateToCampaignDetail(String campaignId) {
  return GlobalVariable.navState.currentState!.push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: campaignId)));
}

class MyCommunity extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Provider(
      auth: AuthService(),
      db: FirebaseFirestore.instance,
      // TODO: implement build
      child: GetMaterialApp(
        navigatorKey: GlobalVariable.navState,
        debugShowCheckedModeBanner: false,
        title: 'MyCommunity',
        theme: ThemeData(
          primaryColor: kPrimaryColor,
          scaffoldBackgroundColor: Colors.white,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: kPrimaryColor,
              shape: const StadiumBorder(),
              maximumSize: const Size(double.infinity, 56),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(
              horizontal: defaultPadding,
              vertical: defaultPadding,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        home: WillStartForegroundTask(
          onWillStart: () async {
            // You can add a foreground task start condition.
            return true; // Replace with your condition if needed
          },
          foregroundTaskOptions: const ForegroundTaskOptions(
            interval: 5000,
            autoRunOnBoot: false,
            allowWifiLock: true,
           ),
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: 'geofence_service_notification_channel',
            channelName: 'Geofence Service Notification',
            channelDescription:
            'This notification appears when the geofence service is running in the background.',
            channelImportance: NotificationChannelImportance.LOW,
            priority: NotificationPriority.LOW,
            isSticky: false,
          ),
          iosNotificationOptions: const IOSNotificationOptions(),
          notificationTitle: 'Geofence Service is running',
          notificationText: 'Tap to return to the app',
          child: _seenOnboarding ? HomeController() : OnboardingScreen()
        ),
        routes: <String, WidgetBuilder>{
          '/home_1': (BuildContext context) => personalBottomNavigationBar(),
          '/home_2': (BuildContext context) => organisationBottomNavigationBar(),
          '/main': (BuildContext context) => WelcomeScreen(),
          '/signin': (BuildContext context) => LoginScreen(),
          '/signup': (BuildContext context) => SignUpScreen(),
        },
      ),
    );
  }
}

class HomeController extends StatefulWidget{
  const HomeController({Key? key}) : super(key: key);

  @override
  _HomeController createState() => _HomeController();
}

class _HomeController extends State<HomeController> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    //activate geofence requirement
    super.initState();
    requestGeofencePermission();
  }

  void requestGeofencePermission() async {
    PermissionStatus status;

    do {
      status = await Permission.activityRecognition.request();

      if (status.isPermanentlyDenied) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Permission Required', style: TextStyle(fontFamily: 'Raleway')),
            content: Text('Please grant the activity recognition permission to use this feature.' , style: TextStyle(fontFamily: 'Raleway')),
            actions: <Widget>[
              TextButton(
                child: Text('Open Settings' , style: TextStyle(fontFamily: 'Raleway')),
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
              ),
            ],
          ),
        );
      }
    } while (!(status.isGranted || status.isPermanentlyDenied));

    do {
      status = await Permission.location.request();

      if (status.isPermanentlyDenied) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Permission Required', style: TextStyle(fontFamily: 'Raleway')),
            content: Text('Please grant the location permission to use this feature.', style: TextStyle(fontFamily: 'Raleway')),
            actions: <Widget>[
              TextButton(
                child: Text('Open Settings', style: TextStyle(fontFamily: 'Raleway')),
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
              ),
            ],
          ),
        );
      }
    } while (!(status.isGranted || status.isPermanentlyDenied));

  }

  Widget build(BuildContext context) {
    lc.Location location = lc.Location();
    bool isLocationServiceEnabled = false;

    return FutureBuilder<User?>(
      future: Future.value(user),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          if (snapshot.hasData) {
            final AuthService auth = Provider.of(context)!.auth;
            // user is logged in, show the authenticated screen
            FirebaseFirestore.instance
                .collection('users_data')
                .doc(auth.getCurrentUID())
                .get()
                .then((value) async {
              var userType = value['usertype'];

              if (userType == "personal" && auth.getUser()!.emailVerified) {

                do{
                  // Check the location service status
                  isLocationServiceEnabled = await location.serviceEnabled();
                  // If the location service is not enabled, show a message to the user
                  if(!isLocationServiceEnabled) {
                    isLocationServiceEnabled = await location.requestService();
                    if (!isLocationServiceEnabled) {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                            AlertDialog(
                              title: Text('Location Service Disabled'),
                              content: Text(
                                  'Please enable Location Service to proceed.'),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                      );
                    }
                  }
                }while(!isLocationServiceEnabled);

                bool isServiceRunning = GeofencingService.geofenceService.isRunningService;
                // Run geofence if service isn't running
                if(!isServiceRunning){
                  print('service activated');
                  //activate geofencing --> user must login in order to get the geofence update --<
                  GeofencingService.startGeofenceUpdates();
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => personalBottomNavigationBar(),
                  ),
                );
                DynamicLinkProvider().initDynamicLink();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(userType),
                  behavior: SnackBarBehavior.floating,
                ));
              }
              else if (userType == "personal" && !auth.getUser()!.emailVerified) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/main', (Route<dynamic> route) => false);
                AuthService.logout();
              }
              else if (userType == "organisation" && auth.getUser()!.emailVerified) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => organisationBottomNavigationBar(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(userType),
                  behavior: SnackBarBehavior.floating,
                ));
              }
              else if (userType == "organisation" && !auth.getUser()!.emailVerified) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/main', (Route<dynamic> route) => false);
                AuthService.logout();
              }
              else {
                Fluttertoast.showToast(
                  backgroundColor: Colors.grey,
                  msg: "Login failed, password or username does not match",
                  gravity: ToastGravity.CENTER,
                  fontSize: 16.0,
                );
              }
            });
          } else {
            // user is not logged in, show the unauthenticated screen
            return const WelcomeScreen();
          }
        }
        // Default return statement
        return const Scaffold(
            body: Center (
                child: CircularProgressIndicator()
            )
        ); // Replace with the appropriate default widget
      },
    );
  }
}




// ignore: camel_case_types
class personalBottomNavigationBar extends StatefulWidget{
  const personalBottomNavigationBar({Key? key}) : super(key: key);

  @override
  _personalBottomNavigationBar createState() => _personalBottomNavigationBar();
}

// ignore: camel_case_types
class _personalBottomNavigationBar extends State<personalBottomNavigationBar>{
  //final user = FirebaseAuth.instance.currentUser;

  final List<Widget> _children = [
    const PersonalHomeScreen(),
    const PersonalActivityScreen(),
    const PersonalCalendarScreen(),
    const PersonalProfileScreen(),
  ];

  final PageStorageBucket bucket = PageStorageBucket();
  Widget currentScreen = PersonalHomeScreen();

  @override
  void initState() {
    super.initState();
    switch(currentIndex){
      case 0:
        currentScreen = _children.first;
        break;
      case 1:
        currentScreen = _children.elementAt(1);
        break;
      case 2:
        currentScreen = _children.elementAt(2);
        break;
      case 3:
        currentScreen = _children.last;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: currentIndex != 3 ? mainBackColor : secBackColor,
      resizeToAvoidBottomInset: false,
      body: PageStorage(
        child: currentScreen,
        bucket: bucket,
      ),
      floatingActionButton:FloatingActionButton( //Floating action button on Scaffold
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateEvent()));//code to execute on button press
        },
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white), //icon inside button
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar : BottomAppBar(
        shape: CircularNotchedRectangle(), //shape of notch
        notchMargin: 10,
        child: Container(
          height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: MaterialButton(
                    minWidth: size.width*0.20,
                    onPressed: (){
                      setState(() {
                        currentScreen = PersonalHomeScreen();
                        currentIndex = 0;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            Icons.home_rounded,
                            color: currentIndex == 0 ? kPrimaryColor : mainTextColor, size: 35,
                        ),
                      ],
                    )
                )),
                Expanded(child: MaterialButton(
                    minWidth: size.width*0.25,
                    onPressed: (){
                      setState(() {
                        currentScreen = PersonalActivityScreen();
                        currentIndex = 1;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            Icons.local_activity_rounded,
                            color: currentIndex == 1 ? kPrimaryColor : mainTextColor, size: 35,
                        ),
                      ],
                    )
                )),
                Expanded(child: const SizedBox()), // this will handle the fab spacing
                Expanded(child: MaterialButton(
                    minWidth: size.width*0.25,
                    onPressed: (){
                      setState(() {
                        currentScreen = PersonalCalendarScreen();
                        currentIndex = 2;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            Icons.calendar_month_rounded,
                            color: currentIndex == 2 ? kPrimaryColor : mainTextColor, size: 35,
                        ),
                      ],
                    )
                )),
                Expanded(child:  MaterialButton(
                    minWidth: size.width*0.25,
                    onPressed: (){
                      setState(() {
                        currentScreen = PersonalProfileScreen();
                        currentIndex = 3;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            Icons.person_rounded,
                            color: currentIndex == 3 ? kPrimaryColor : mainTextColor, size: 35,
                        ),
                      ],
                    )
                )),
              ],
            )
        ),),
    );
  }
}


// ignore: camel_case_types
class organisationBottomNavigationBar extends StatefulWidget{
  const organisationBottomNavigationBar({Key? key}) : super(key: key);

  @override
  _organisationBottomNavigationBar createState() => _organisationBottomNavigationBar();
}

// ignore: camel_case_types
class _organisationBottomNavigationBar extends State<organisationBottomNavigationBar>{
  //final user = FirebaseAuth.instance.currentUser;


  final List<Widget> _children = [
    const OrganisationHomeScreen(),
    const OrganisationCampaignScreen(),
    const OrganisationCampaignStatisticsScreen(),
    const OrganisationProfileScreen(),
  ];

  void onTappedBar(int index){
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
       child: _children[currentIndex],
      ),
      bottomNavigationBar : Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.bottomCenter, colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.7)
            ])),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2B65EC),
          unselectedItemColor: mainTextColor,
          // selectedFontSize: 16,
          // unselectedFontSize: 13,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          onTap: onTappedBar,

          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: 35),
                label: ""),

            BottomNavigationBarItem(
              icon: Icon(Icons.local_activity_rounded, size: 35),
                label: ""),

            BottomNavigationBarItem(
              icon: Icon(Icons.dataset_rounded, size: 35),
              label: ""),

            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 35),
              label: ""),
          ],
        ),),
    );
  }
}