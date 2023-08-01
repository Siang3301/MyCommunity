import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import 'package:mycommunity/initial_screens/components/forgotpassword.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/initial_screens/components/or_divider.dart';
import 'package:mycommunity/initial_screens/Login/components/background.dart';
import 'package:mycommunity/initial_screens/components/already_have_an_account_acheck.dart';
import 'package:mycommunity/initial_screens/components/rounded_button.dart';
import 'package:mycommunity/initial_screens/components/rounded_button_google.dart';
import 'package:mycommunity/initial_screens/components/rounded_input_field.dart';
import 'package:mycommunity/initial_screens/components/rounded_password_field.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mycommunity/initial_screens/forget_password/forget_screen.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/body.dart';
import 'package:mycommunity/main.dart';
import 'package:mycommunity/services/geofencing_service.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';

class LoginBody extends StatefulWidget{
  const LoginBody({Key? key}) : super(key: key);

  @override
  _LoginBody createState() => _LoginBody();
}

class _LoginBody extends State<LoginBody> {
  final _formKey = GlobalKey<FormState>();
  String _email = "", _password = "";


  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;
    Location location = Location();
    bool isLocationServiceEnabled = false;

    return Scaffold(
      body: Form(
        key: _formKey,
        child: Background(
        child: SingleChildScrollView(
          child: Container(
            height: size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 110, right: 250),
              child: const Text(
              "Sign in",
              style: TextStyle(fontWeight: FontWeight.normal, fontSize: 25, color: kPrimaryColor, fontFamily: 'Raleway'),
            ),
            ),
            SizedBox(height: size.height * 0.06),
            RoundedInputField(
              onChanged: (value) {
                setState(() {
                  _email = value.trim();
                });
              },
            ),
            SizedBox(height: size.height * 0.01),
            RoundedPasswordField(
              onChanged: (value) {
                setState(() {
                  _password = value.trim();
                });
              },
            ),
            SizedBox(height: size.height * 0.02),
            ForgotPassword(
                press: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgetScreen()));
                }
            ),
            SizedBox(height: size.height * 0.01),
            AlreadyHaveAnAccountCheck(
              press: () {
                initialRouteIncrement++;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const PersonalSignupBody();
                    },
                  ),
                );
              },
            ),
            SizedBox(height: size.height * 0.03),
            RoundedButton(
              text: "LOGIN",
              press: () async {
                setState(() {
                });
                if (_formKey.currentState!.validate() && EmailValidator.validate(_email.trim())) {
                  try {
                    final user = await auth.signIn(
                        email: _email, password: _password).then((result) {
                          FirebaseFirestore.instance
                          .collection('users_data')
                          .doc(auth.getCurrentUID())
                          .get()
                          .then((value) async{
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
                              showEmailVerificationDialog(context);
                            }
                            else if (userType == "organisation" && auth.getUser()!.emailVerified) {
                              Navigator.of(context)
                                  .pushNamedAndRemoveUntil('/home_2', (Route<dynamic> route) => false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(userType), behavior: SnackBarBehavior.floating));
                            }
                            else if (userType == "organisation" && !auth.getUser()!.emailVerified) {
                              showEmailVerificationDialog(context);
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
                    });
                  } catch(e){
                    Fluttertoast.showToast(
                      backgroundColor: Colors.grey,
                      msg: "Login failed, password or username does not match",
                      gravity: ToastGravity.CENTER,
                      fontSize: 16.0,
                    );
                  }
                }
              },
            ),
            const OrDivider(),
            RoundedButtonGoogle(
              text: "SIGN IN WITH GOOGLE",
              press: () async {
                setState(() {
                });

                User? user =
                await auth.signInWithGoogle(context: context);

                if(user != null){
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
                      showEmailVerificationDialog(context);
                    }
                    else if (userType == "organisation" && auth.getUser()!.emailVerified) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/home_2', (Route<dynamic> route) => false);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(userType), behavior: SnackBarBehavior.floating));
                    }
                    else if (userType == "organisation" && !auth.getUser()!.emailVerified) {
                      showEmailVerificationDialog(context);
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
                }
              },
            ),
            Spacer(),
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
    )
    ),
    )
    )
    );
  }
}

showEmailVerificationDialog(BuildContext context) {
  final auth = Provider.of(context)!.auth;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Account Verification', style: TextStyle(fontFamily: 'Raleway')),
        content: Text(
            'You must verify your account via the verification email that was sent to your email address. If you did not receive the email, you can send it again.',
            style: TextStyle(fontFamily: 'SourceSansPro')
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Send', style: TextStyle(fontFamily: 'Raleway')),
            onPressed: () {
              // Send email verification
              FirebaseAuth.instance.currentUser!.sendEmailVerification();
              Navigator.of(context).pop(); // Close the dialog
              auth.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Verification email has been sent to your inbox.'), behavior: SnackBarBehavior.floating));
            },
          ),
          TextButton(
            child: Text('OK', style: TextStyle(fontFamily: 'Raleway')),
            onPressed: () {
              auth.signOut();
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}





