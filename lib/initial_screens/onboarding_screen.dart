import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart' as lc;
import 'package:mycommunity/initial_screens/components/onboard_content.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

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
  void initState() {
    super.initState();
    requestGeofencePermission();
    Future.delayed(Duration.zero, () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(42),
            topRight: Radius.circular(42),
          ),
        ),
        isDismissible: false, // prevent dismissing the bottom sheet by dragging it down
        builder: (_) => GestureDetector(
          onTap: () {}, // prevent tap gestures from dismissing the bottom sheet
          onVerticalDragDown: (_) {}, // prevent drag gestures from dismissing the bottom sheet
          child: const OnboardContent(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Image.asset(
        "assets/images/bg.png",
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
