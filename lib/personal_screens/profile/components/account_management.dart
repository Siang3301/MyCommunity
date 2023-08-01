import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mycommunity/personal_screens/profile/components/rounded_ic_field.dart';
import 'package:mycommunity/personal_screens/profile/components/rounded_address_field.dart';
import 'package:mycommunity/personal_screens/profile/components/rounded_city_field.dart';
import 'package:mycommunity/personal_screens/profile/components/rounded_contact_field.dart';
import 'package:mycommunity/personal_screens/profile/components/rounded_name_field.dart';
import 'package:mycommunity/personal_screens/profile/components/rounded_age_field.dart';
import 'package:mycommunity/personal_screens/profile/components/or_divider.dart';
import 'package:mycommunity/personal_screens/profile/components/rounded_postal_field.dart';
import 'package:mycommunity/personal_screens/profile/components/rounded_state_field.dart';
import 'package:mycommunity/personal_screens/profile/model/user.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/personal_screens/profile/components/background.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';


class AccountManagement extends StatefulWidget{
  final String userID;
  const AccountManagement({Key? key, required this.userID}) : super(key: key);

  @override
  _AccountManagement createState() => _AccountManagement();
}


class _AccountManagement extends State<AccountManagement> {
  late Future<Personal?> _futureProfile;

  @override
  void initState() {
    super.initState();
    _futureProfile = getPersonalProfile(widget.userID);
  }

  Future<Personal?> getPersonalProfile(String userID) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users_data')
          .doc(userID)
          .get();

      if (doc.exists) {
        Personal personal = Personal.fromFirestore(doc);
        return personal;
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
      body: FutureBuilder<Personal?>(
        future: _futureProfile,
        builder: (BuildContext context, AsyncSnapshot<Personal?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return EditPersonalInterface(personal: snapshot.data!, userID: widget.userID);
          }
        },
      ),
    );
  }
}

class EditPersonalInterface extends StatefulWidget {
  final Personal personal;
  final String userID;

  EditPersonalInterface({required this.personal, required this.userID});

  @override
  _EditPersonalInterface createState() => _EditPersonalInterface();
}

class _EditPersonalInterface extends State<EditPersonalInterface> {
  final _formKey = GlobalKey<FormState>();
  String name = '', age = '', ic = '', contact = '', address = '', postal = '', city = '', state = '';
  late Personal _personal;

  @override
  void initState() {
    super.initState();
    _personal = widget.personal;
    name = _personal.name;
    ic = _personal.ic;
    age = _personal.age;
    contact = _personal.contact;
    address = _personal.address;
    postal = _personal.postal;
    city = _personal.city;
    state = _personal.state;
  }

  //Update Personal profile to Database
  Future<void> updatePersonalProfile(BuildContext context, Map<String, dynamic> dataToUpdate, String userID) async {
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
                "Updating your user account's profile...",
                style: TextStyle(fontFamily: 'Raleway'),
              ),
            ],
          ),
        ),
      );

      // Update campaign data to Firestore without image updated

      await FirebaseFirestore.instance.collection("users_data").doc(userID).update({
          "username": dataToUpdate['name'],
          "identification_number": dataToUpdate['ic'],
          "age": dataToUpdate['age'],
          "contact": dataToUpdate['contact'],
          "city": dataToUpdate['city'],
          "address": dataToUpdate['address'],
          "postal": dataToUpdate['postal'],
          "state": dataToUpdate['state'],
      });

      auth.getUser()?.updateDisplayName(dataToUpdate['name']);

      // Hide loading dialog and show success dialog
      Navigator.of(context).pop(); // Dismiss previous dialog

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            "Your profile updated successfully!",
            style: TextStyle(fontFamily: 'Raleway'),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home_1',
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
            "An error occurred while updating the profile: $error",
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
          title:  const Text("Account Management", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
          backgroundColor: Colors.white,
          bottomOpacity: 0.0,
          elevation: 0.0,
        ),
        body:  Form(
            key: _formKey,
            child: Background(
              child: SafeArea(
                child: SingleChildScrollView(
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
                        const Text("Personal Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway", color: mainTextColor)),
                        SizedBox(height: size.height * 0.015),
                        const Text("Your personal information will be used for validation and recommendation of possible community service activities.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        SizedBox(height: size.height * 0.015),
                        const CustomDivider(text: "Profile"),
                        SizedBox(height: size.height * 0.015),
                        Center(
                            child : RoundedNameField(
                              onChanged: (value) {
                                setState(() {
                                  name = value.trim();
                                });
                              },
                              initialValue: name,
                            )
                        ),
                        Center(
                            child : RoundedAgeField(
                              onChanged: (value) {
                                setState(() {
                                  age = value.trim();
                                });
                              },
                              initialValue: age,
                            )
                        ),
                        Center(
                            child : RoundedIcField(
                              onChanged: (value) {
                                setState(() {
                                  ic = value.trim();
                                });
                              },
                              initialValue: ic,
                            )
                        ),
                        Center(
                            child : RoundedContactField(
                              onChanged: (value) {
                                setState(() {
                                  contact = value.trim();
                                });
                              },
                              initialValue: contact,
                            )
                        ),
                        SizedBox(height: size.height * 0.01),
                        const CustomDivider(text: "Personal Address"),
                        SizedBox(height: size.height * 0.015),
                        Center(
                            child : RoundedAddressField(
                              onChanged: (value) {
                                setState(() {
                                  address = value.trim();
                                });
                              },
                              initialValue: address,
                            )
                        ),
                        Center(
                            child : RoundedCityField(
                              onChanged: (value) {
                                setState(() {
                                  city = value.trim();
                                });
                              },
                              initialValue: city,
                            )
                        ),
                        Center(
                            child : RoundedPostalField(
                              onChanged: (value) {
                                setState(() {
                                  postal = value.trim();
                                });
                              },
                              initialValue: postal,
                            )
                        ),
                        Center(
                            child : RoundedStateField(
                              onChanged: (value) {
                                setState(() {
                                  state = value.trim();
                                });
                              },
                              initialValue: state,
                            )
                        ),
                        SizedBox(height: size.height * 0.015),
                        Center(
                          child: Container(
                            alignment: Alignment.center,
                            width: size.width * 0.45,
                            height: size.height * 0.06,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              shape: BoxShape.rectangle,
                            ),
                            child:ElevatedButton(
                              onPressed: ()  {
                                if (_formKey.currentState!.validate()) {
                                  Map<String, dynamic> newData = {
                                    'name': name,
                                    'ic': ic,
                                    'age'  : age,
                                    'contact': contact,
                                    'address': address,
                                    'city': city,
                                    'postal': postal,
                                    'state': state
                                  };

                                  if(newData != null){
                                    showDoubleConfirmDialog(context).then((confirmed) {
                                      if (confirmed) {
                                        updatePersonalProfile(context, newData, widget.userID);
                                      }
                                    });
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor
                              ),
                              child: const Text(
                                "SAVE AND UPDATE", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                              ),
                            )
                          )
                        ),
                      ],
                     ),
                    )
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
            'Are you sure you want to update your personal profile?',
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


