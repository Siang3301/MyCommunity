import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mycommunity/organisation_screens/profile/model/user.dart';
import 'package:mycommunity/organisation_screens/profile/components/rounded_feedback_field.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/personal_screens/profile/components/background.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';


class WriteFeedback extends StatefulWidget{
  final String userID;
  const WriteFeedback({Key? key, required this.userID}) : super(key: key);

  @override
  _WriteFeedback createState() => _WriteFeedback();
}


class _WriteFeedback extends State<WriteFeedback> {
  late Future<Organisation?> _futureProfile;

  @override
  void initState() {
    super.initState();
    _futureProfile = getOrganisationProfile(widget.userID);
  }

  Future<Organisation?> getOrganisationProfile(String userID) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users_data')
          .doc(userID)
          .get();

      if (doc.exists) {
        Organisation organisation = Organisation.fromFirestore(doc);
        organisation.email = doc['email'];
        return organisation;
      } else {
        return null;
      }
    } catch (e) {
      print('Error retrieving campaign data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Organisation?>(
        future: _futureProfile,
        builder: (BuildContext context, AsyncSnapshot<Organisation?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return EditOrganisationInterface(organisation: snapshot.data!, userID: widget.userID);
          }
        },
      ),
    );
  }
}

class EditOrganisationInterface extends StatefulWidget {
  final Organisation organisation;
  final String userID;

  EditOrganisationInterface({required this.organisation, required this.userID});

  @override
  _EditOrganisationInterface createState() => _EditOrganisationInterface();
}

class _EditOrganisationInterface extends State<EditOrganisationInterface> {
  final _formKey = GlobalKey<FormState>();
  String orgName = '', orgType = '', orgID = '', contact = '', address = '', postal = '', city = '', state = '', feedback = '', email = '';
  late Organisation _organisation;

  @override
  void initState() {
    super.initState();
    _organisation = widget.organisation;
    orgName = _organisation.orgName;
    orgType = _organisation.orgType;
    orgID = _organisation.orgID;
    contact = _organisation.contact;
    address = _organisation.address;
    postal = _organisation.postal;
    city = _organisation.city;
    state = _organisation.state;
    email = _organisation.email;
  }

  //Update Personal profile to Database
  Future<void> sendFeedback(BuildContext context, String userID, String userName, String email, String contact, String feedback) async {
    final auth = Provider.of(context)!.auth;

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
                "Sending your feedback to admin...",
                style: TextStyle(fontFamily: 'Raleway'),
              ),
            ],
          ),
        ),
      );

      // Send feedback to firestore
      await FirebaseFirestore.instance.collection("users_feedback").add({
        'userID': userID,
        'userName': userName,
        'userType': 'organisation',
        'email': email,
        'contact': contact,
        'feedback': this.feedback,
      });

      // Hide loading dialog and show success dialog
      Navigator.of(context).pop(); // Dismiss previous dialog

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            "Your feedback sent successfully!",
            style: TextStyle(fontFamily: 'Raleway'),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil(
                     '/home_2',
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
            "An error occurred while sending the feedback: $error",
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
    final username = auth.getUser()!.displayName as String;

    return Scaffold(
        backgroundColor: secBackColor,
        appBar : AppBar(
          leading: const BackButton(color: kPrimaryColor),
          centerTitle: false,
          title:  const Text("User Feedback", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
          backgroundColor: Colors.white,
          bottomOpacity: 0.0,
          elevation: 0.0,
        ),
        body:  Form(
            key: _formKey,
            child: Background(
              child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text("Feedback", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway", color: mainTextColor)),
                        SizedBox(height: size.height * 0.015),
                        const Text("Your personal feedback will be sent to our admin, if there is any issue we will reply to you as soon as possible.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        SizedBox(height: size.height * 0.04),
                        Center(
                            child : RoundedFeedbackField(
                              onChanged: (value) {
                                setState(() {
                                  feedback = value.trim();
                                });
                              },
                            )
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                          child: Container(
                            alignment: Alignment.bottomCenter,
                            width: size.width * 0.45,
                            height: size.height * 0.06,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              shape: BoxShape.rectangle,
                            ),
                            child:ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                    showDoubleConfirmDialog(context).then((confirmed) async {
                                      if (confirmed) {
                                        await sendFeedback(context, widget.userID, orgName, email, contact, feedback);
                                      }
                                    });
                                  }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: orgMainColor
                              ),
                              child: const Text(
                                "SEND FEEDBACK", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                              ),
                            )
                           )
                          )
                        ),
                      ],
                     ),
                    )
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
            'Are you sure you want to send the feedback to admin?',
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


