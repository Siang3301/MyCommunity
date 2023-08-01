import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mycommunity/organisation_screens/profile/components/rounded_address_field.dart';
import 'package:mycommunity/organisation_screens/profile/components/rounded_city_field.dart';
import 'package:mycommunity/organisation_screens/profile/components/rounded_contact_field.dart';
import 'package:mycommunity/organisation_screens/profile/components/rounded_id_field.dart';
import 'package:mycommunity/organisation_screens/profile/components/or_divider.dart';
import 'package:mycommunity/organisation_screens/profile/components/rounded_org_name_field.dart';
import 'package:mycommunity/organisation_screens/profile/components/rounded_postal_field.dart';
import 'package:mycommunity/organisation_screens/profile/components/rounded_state_field.dart';
import 'package:mycommunity/organisation_screens/profile/components/rounded_type_field.dart';
import 'package:mycommunity/organisation_screens/profile/model/user.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/organisation_screens/profile/components/background.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';


class AccountManagement extends StatefulWidget{
  final String userID;
  const AccountManagement({Key? key, required this.userID}) : super(key: key);

  @override
  _AccountManagement createState() => _AccountManagement();
}


class _AccountManagement extends State<AccountManagement> {
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
  String orgName = '', orgType = '', orgID = '', contact = '', address = '', postal = '', city = '', state = '';
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
  }

  void _handleCategorySelected(String cat) {
    setState(() {
      orgType = cat;
    });
  }

  //Update Organisation profile to Database
  Future<void> updateOrgProfile(BuildContext context, Map<String, dynamic> dataToUpdate, String userID) async {
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
                "Updating organisation profile...",
                style: TextStyle(fontFamily: 'Raleway'),
              ),
            ],
          ),
        ),
      );

      // Update campaign data to Firestore without image updated

      await FirebaseFirestore.instance.collection("users_data").doc(userID).update({
          "organisation_name": dataToUpdate['orgName'],
          "organisation_ID": dataToUpdate['orgID'],
          "organisation_type": dataToUpdate['orgType'],
          "contact": dataToUpdate['contact'],
          "city": dataToUpdate['city'],
          "address": dataToUpdate['address'],
          "postal": dataToUpdate['postal'],
          "state": dataToUpdate['state'],
      });

      auth.getUser()?.updateDisplayName(dataToUpdate['orgName']);

      // Hide loading dialog and show success dialog
      Navigator.of(context).pop(); // Dismiss previous dialog

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            "Organisation profile updated successfully!",
            style: TextStyle(fontFamily: 'Raleway'),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home_2', (route) => false,
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
            "An error occurred while updating the organisation profile: $error",
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
                        const Text("Organisation Information", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway", color: mainTextColor)),
                        SizedBox(height: size.height * 0.015),
                        const Text("Your organisation information will be used for validation and promotion of community service activities.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        SizedBox(height: size.height * 0.015),
                        const CustomDivider(text: "Profile"),
                        SizedBox(height: size.height * 0.015),
                        Center(
                            child : RoundedOrgNameField(
                              onChanged: (value) {
                                setState(() {
                                  orgName = value.trim();
                                });
                              },
                              initialValue: orgName,
                            )
                        ),
                        Center(
                            child : RoundedCategoryField(
                                onCategorySelected: _handleCategorySelected, initialValue: orgType
                            )
                        ),
                        SizedBox(height: size.height * 0.02),
                        Center(
                            child : RoundedIdField(
                              onChanged: (value) {
                                setState(() {
                                  orgID = value.trim();
                                });
                              },
                              initialValue: orgID,
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
                        const CustomDivider(text: "Organisation Address"),
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
                                    'orgName': orgName,
                                    'orgType': orgType,
                                    'orgID'  : orgID,
                                    'contact': contact,
                                    'address': address,
                                    'city': city,
                                    'postal': postal,
                                    'state': state
                                  };

                                  if(newData != null){
                                    showDoubleConfirmDialog(context).then((confirmed) {
                                      if (confirmed) {
                                        updateOrgProfile(context, newData, widget.userID);
                                      }
                                    });
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: orgMainColor
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
            'Are you sure you want to update the organisation profile?',
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


