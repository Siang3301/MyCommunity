import 'package:flutter/material.dart';
import 'package:location/location.dart' as lc;
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/initial_screens/Login/login_screen.dart';
import 'package:mycommunity/initial_screens/Welcome/components/background.dart';
import 'package:mycommunity/initial_screens/signup/signup_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  void initState() {
    //activate geofence requirement
    super.initState();
    requestGeofencePermission();
  }

  void requestGeofencePermission() async {
    PermissionStatus status;
    bool serviceEnabled = false;
    lc.Location location = lc.Location();

    do {
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text('Please enable Location Services to proceed.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        }
      }
    } while (!serviceEnabled);

    do {
      status = await Permission.activityRecognition.request();

      if (status.isPermanentlyDenied) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Permission Required', style: TextStyle(fontFamily: 'Raleway')),
            content: Text('Please grant the activity recognition permission before you use the application.' , style: TextStyle(fontFamily: 'Raleway')),
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
            content: Text('Please grant the location permission before you use the application.', style: TextStyle(fontFamily: 'Raleway')),
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // This size provides us the total height and width of our screen
    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: size.height * 0.08),
            Container(
              alignment: Alignment.center,
              child: const Text(
                "MyCommunity",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  fontFamily: 'Raleway',
                  color: kSecondaryColor,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.white,
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.fromLTRB(0, 7, 0, 0),
              child: const Text(
                "Make Your Impact Today!",
                style: TextStyle(
                  fontSize: 23,
                  color: mainTextColor,
                  fontFamily: "SourceSansPro",
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.white,
                      offset: Offset(3.0, 3.0),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: size.height * 0.05),
            Image.asset(
              "assets/icons/mycommunity.png",
              height: size.height * 0.30,
            ),
            SizedBox(height: size.height * 0.07),
            SizedBox(
              width: 300,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const LoginScreen();
                      },
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: kPrimaryColor,
                ),
                child: const Text(
                  "LOGIN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Raleway",
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.02),
            SizedBox(
              width: 300,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const SignUpScreen();
                      },
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(width: 1.0, color: kPrimaryColor),
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  "SIGN UP",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: "Raleway",
                    fontSize: 18,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.05),
          ],
        ),
      ),
    );
  }
}