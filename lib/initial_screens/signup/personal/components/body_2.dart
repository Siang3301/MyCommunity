import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:mycommunity/services/auth_service.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/initial_screens/Login/login_screen.dart';
import 'package:mycommunity/initial_screens/Signup/personal/components/background.dart';
import 'package:mycommunity/initial_screens/components/already_have_an_account_acheck.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/rounded_address_field.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/rounded_age_field.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/rounded_city_field.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/rounded_contact_field.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/rounded_ic_field.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/rounded_postal_field.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/rounded_state_field.dart';
import 'package:mycommunity/services/geofencing_service.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';


class PersonalSignupBody_2 extends StatefulWidget{
  final String name, email, password, option;
  const PersonalSignupBody_2({Key? key, required this.name, required this.email, required this.password, required this.option}) : super(key: key);

  @override
  _SignupBody createState() => _SignupBody();
}


class _SignupBody extends State<PersonalSignupBody_2> {
  final _formKey = GlobalKey<FormState>();
  Location location = Location();
  bool isLocationServiceEnabled = false;

  // text field state
  String age = '';
  String ic = '';
  String contact = '';
  String address = '';
  String postal = '';
  String city = '';
  String state = '';
  String usertype = 'personal';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        body: Form(
            key: _formKey,
            child:Background(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 50, right: 225),
                    ),
                    const Text("Step 2 of 2: Person details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway")),
                    SizedBox(height: size.height * 0.03),
                    const Text("Your profile details will be used for \n events recommendation purposes only.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                    SizedBox(height: size.height * 0.03),
                    RoundedAgeField(
                      onChanged: (value) {
                        setState(() {
                          age = value.trim();
                        });
                      },
                    ),
                    RoundedIcField(
                      onChanged: (value) {
                        setState(() {
                          ic = value.trim();
                        });
                      },
                    ),
                    RoundedContactField(
                      onChanged: (value) {
                        setState(() {
                          contact = value.trim();
                        });
                      },
                    ),
                    RoundedAddressField(
                      onChanged: (value) {
                        setState(() {
                          address = value.trim();
                        });
                      },
                    ),
                    RoundedPostalField(
                      onChanged: (value) {
                        setState(() {
                          postal = value.trim();
                        });
                      },
                    ),
                    RoundedCityField(
                      onChanged: (value) {
                        setState(() {
                          city = value.trim();
                        });
                      },
                    ),
                    RoundedStateField(
                      onChanged: (value) {
                        setState(() {
                          state = value.trim();
                        });
                      },
                    ),
                    SizedBox(height: size.height * 0.03),
                    Container(
                      alignment: Alignment.bottomRight,
                      width: size.width * 0.25,
                      margin: EdgeInsets.only(left: size.width*0.60),
                      padding: const EdgeInsets.all(5),
                      height: size.height * 0.06,
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(12.0),
                        shape: BoxShape.rectangle,
                      ),
                    child:ElevatedButton(
                        onPressed: () async {
                          initialRouteIncrement++;
                          if (_formKey.currentState!.validate()) {
                            switch(widget.option){
                              case 'google':
                                final result = await
                                  auth.signUpUserWithGoogle(
                                    email: widget.email.trim(), name: widget.name.trim(), age: age.trim(),
                                    ic: ic.trim(), contact: contact.trim(), address: address.trim(),
                                    postal: postal.trim(), city: city.trim(), state: state.trim(),
                                    usertype: usertype.trim()
                                  );
                                if (result == "Signed up") {
                                  _showDialog2(context);
                                }
                              break;

                              case 'email':
                                final result = await
                                auth.signUpUserWithEmailAndPassword(
                                  email: widget.email.trim(), password: widget.password.trim(), name: widget.name.trim(),
                                  age: age.trim(), ic: ic.trim(), contact: contact.trim(), address: address.trim(),
                                  postal: postal.trim(), city: city.trim(), state: state.trim(), usertype: usertype.trim()
                                );

                                if (result == "Signed up") {
                                  AuthService.logout();
                                  _showDialog(context);
                                }

                                break;
                            }
                          }
                        },
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "SIGN UP", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                            ),
                          ),
                        )
                    ),
                    SizedBox(height: size.height * 0.03),
                    Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.all(10),
                      child: const Text(
                        "By signing up you agree with our terms and to receive periodic updates and tips.", textAlign: TextAlign.center,
                        style : TextStyle(fontSize: 13, color: mainTextColor, fontFamily: "SourceSansPro"
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
        )
    );
  }

  void _showDialog(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: size.width*0.20),
          alignment: Alignment.center,
          child: Container(
            height: size.height*0.50,
            child: Column(
              children: [
                SizedBox(height: size.height * 0.02),
                Image.asset("assets/icons/success.png", width: 40,height: 40,fit:BoxFit.contain),
                SizedBox(height: size.height * 0.03),
                const Text("Register Success!"),
                SizedBox(height: size.height * 0.02),
                const Divider(
                    color: Color(0xFF707070),
                    thickness: 1.0,
                ),
                SizedBox(height: size.height * 0.03),
                Container(
                  margin: const EdgeInsets.all(10),
                  child : const Text(
                    "Congratulation, your profile account has been created successfully, \n A verification email has been sent to your email, please verify your account before login!", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontFamily: "SourceSansPro", color: darkTextColor),
                  ),
                ),
                SizedBox(height: size.height * 0.06),
                Expanded(
                child:Container(
                  alignment: Alignment.bottomCenter,
                  width: size.width*0.35,
                  padding: const EdgeInsets.only(bottom: 15),
                  child:TextButton(
                    style: ButtonStyle(
                        padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(15)),
                        foregroundColor: MaterialStateProperty.all<Color>(kPrimaryColor),
                        backgroundColor: MaterialStateProperty.all<Color>(kPrimaryColor),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13.0),
                                side: BorderSide(color: kPrimaryColor),
                            )
                        )
                    ),
                    onPressed: (){
                      switch(widget.option) {
                        case 'email':
                          auth.signOut();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/signin', // Replace with the name of the route you want to navigate to
                            ModalRoute.withName('/'), // Remove all previous routes except the initial route
                          );
                        break;

                        case 'google':
                          final auth = Provider.of(context)!.auth;
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
                                if (!isLocationServiceEnabled) {
                                  await showDialog(
                                      context: context,
                                      builder: (BuildContext context) => AlertDialog(
                                    title: Text('Location Service Disabled'),
                                    content: Text('Please enable Location Service to proceed.'),
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
                              }while(!isLocationServiceEnabled);

                              bool isServiceRunning = GeofencingService.geofenceService.isRunningService;
                              // Run geofence if service isn't running
                              if(!isServiceRunning){
                                print('service activated');
                                //activate geofencing --> user must login in order to get the geofence update --<
                                GeofencingService.startGeofenceUpdates();
                              }
                              Navigator.of(context)
                                  .pushNamedAndRemoveUntil('/home_1', (Route<dynamic> route) => false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(userType), behavior: SnackBarBehavior.floating));
                            }
                            else if (userType == "personal" && !auth.getUser()!.emailVerified) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/signin', // Replace with the name of the route you want to navigate to
                                ModalRoute.withName('/'), // Remove all previous routes except the initial route
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('You must verify your account before you can login.'), behavior: SnackBarBehavior.floating));
                            }
                            else if (userType == "organisation" && auth.getUser()!.emailVerified) {
                              Navigator.of(context)
                                  .pushNamedAndRemoveUntil('/home_2', (Route<dynamic> route) => false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(userType), behavior: SnackBarBehavior.floating));
                            }
                            else if (userType == "organisation" && !auth.getUser()!.emailVerified) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/signin', // Replace with the name of the route you want to navigate to
                                ModalRoute.withName('/'), // Remove all previous routes except the initial route
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('You must verify your account before you can login.'), behavior: SnackBarBehavior.floating));
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
                        break;
                     }
                    },
                    child: Text(
                        "Login".toUpperCase(),
                        style: TextStyle(fontSize: 14, fontFamily: "Raleway", color: Colors.white)
                    )
                  ),
                 ),
                )
              ]
            ),
          )
          );
      },
    );
  }
  void _showDialog2(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: size.width*0.20),
            alignment: Alignment.center,
            child: Container(
              height: size.height*0.50,
              child: Column(
                  children: [
                    SizedBox(height: size.height * 0.02),
                    Image.asset("assets/icons/success.png", width: 40,height: 40,fit:BoxFit.contain),
                    SizedBox(height: size.height * 0.03),
                    const Text("Register Success!"),
                    SizedBox(height: size.height * 0.02),
                    const Divider(
                      color: Color(0xFF707070),
                      thickness: 1.0,
                    ),
                    SizedBox(height: size.height * 0.03),
                    Container(
                      margin: const EdgeInsets.all(10),
                      child : const Text(
                        "Congratulation, your profile account has been created successfully, \n Press the button below to login now!", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontFamily: "SourceSansPro", color: darkTextColor),
                      ),
                    ),
                    SizedBox(height: size.height * 0.06),
                    Expanded(
                    child:Container(
                      alignment: Alignment.bottomCenter,
                      width: size.width*0.35,
                      padding: const EdgeInsets.only(bottom: 15),
                      child:TextButton(
                          style: ButtonStyle(
                              padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(15)),
                              foregroundColor: MaterialStateProperty.all<Color>(kPrimaryColor),
                              backgroundColor: MaterialStateProperty.all<Color>(kPrimaryColor),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13.0),
                                    side: BorderSide(color: kPrimaryColor),
                                  )
                              )
                          ),
                          onPressed: (){
                            switch(widget.option) {
                              case 'email':
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/signin', // Replace with the name of the route you want to navigate to
                                  ModalRoute.withName('/'), // Remove all previous routes except the initial route
                                );
                                break;

                              case 'google':
                                final auth = Provider.of(context)!.auth;
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
                                      if (!isLocationServiceEnabled) {
                                        await showDialog(
                                            context: context,
                                            builder: (BuildContext context) => AlertDialog(
                                          title: Text('Location Service Disabled'),
                                          content: Text('Please enable Location Service to proceed.'),
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
                                    }while(!isLocationServiceEnabled);

                                    bool isServiceRunning = GeofencingService.geofenceService.isRunningService;
                                    // Run geofence if service isn't running
                                    if(!isServiceRunning){
                                      print('service activated');
                                      //activate geofencing --> user must login in order to get the geofence update --<
                                      GeofencingService.startGeofenceUpdates();
                                    }
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil('/home_1', (Route<dynamic> route) => false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(userType), behavior: SnackBarBehavior.floating));
                                  }
                                  else if (userType == "personal" && !auth.getUser()!.emailVerified) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/signin', // Replace with the name of the route you want to navigate to
                                      ModalRoute.withName('/'), // Remove all previous routes except the initial route
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('You must verify your account before you can login.'), behavior: SnackBarBehavior.floating));
                                  }
                                  else if (userType == "organisation" && auth.getUser()!.emailVerified) {
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil('/home_2', (Route<dynamic> route) => false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(userType), behavior: SnackBarBehavior.floating));
                                  }
                                  else if (userType == "organisation" && !auth.getUser()!.emailVerified) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/signin', // Replace with the name of the route you want to navigate to
                                      ModalRoute.withName('/'), // Remove all previous routes except the initial route
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('You must verify your account before you can login.'), behavior: SnackBarBehavior.floating));
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
                                break;
                            }
                          },
                          child: Text(
                              "Login".toUpperCase(),
                              style: TextStyle(fontSize: 14, fontFamily: "Raleway", color: Colors.white)
                          )
                      ),
                     ),
                    )
                  ]
              ),
            )
        );
      },
    );
  }

}



