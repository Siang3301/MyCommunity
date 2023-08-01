import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mycommunity/personal_screens/profile/model/user.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/personal_screens/profile/components/background.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';


class PreferencesManagement extends StatefulWidget{
  final String userID;
  const PreferencesManagement({Key? key, required this.userID}) : super(key: key);

  @override
  _PreferencesManagement createState() => _PreferencesManagement();
}


class _PreferencesManagement extends State<PreferencesManagement> {
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
            return EditPreferencesInterface(personal: snapshot.data!, userID: widget.userID);
          }
        },
      ),
    );
  }
}

class EditPreferencesInterface extends StatefulWidget {
  final Personal personal;
  final String userID;

  EditPreferencesInterface({required this.personal, required this.userID});

  @override
  _EditPreferencesInterface createState() => _EditPreferencesInterface();
}

class _EditPreferencesInterface extends State<EditPreferencesInterface> {
  final _formKey = GlobalKey<FormState>();
  late Personal _personal;
  List<dynamic> selectedPreferences = [];

  List<dynamic> allCategories = [
    'Aid & Community',
    'Animal Welfare',
    'Art & Culture',
    'Children & Youth',
    'Education & Lectures',
    'Disabilities',
    'Environment',
    'Food & Hunger',
    'Health & Medical',
    'Technology',
    'Skill-based Volunteering',
  ];

  @override
  void initState() {
    super.initState();
    _personal = widget.personal;
    selectedPreferences = _personal.preferences;
    print(selectedPreferences);
  }

  //Update Personal profile to Database
  Future<void> updatePersonalInterest(BuildContext context, List<dynamic> preferences, String userID) async {

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
                "Updating your user account's preferences...",
                style: TextStyle(fontFamily: 'Raleway'),
              ),
            ],
          ),
        ),
      );

      // Update campaign data to Firestore without image updated
      await FirebaseFirestore.instance.collection("users_data").doc(userID).update({
          "preferences": preferences
      });

      // Hide loading dialog and show success dialog
      Navigator.of(context).pop(); // Dismiss previous dialog

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            "Your preferences updated successfully!",
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
            "An error occurred while updating the preferences: $error",
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

    return Scaffold(
        backgroundColor: secBackColor,
        appBar : AppBar(
          leading: const BackButton(color: kPrimaryColor),
          centerTitle: false,
          title:  const Text("Activity Preferences", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
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
                        const Text("Personal Interest", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway", color: mainTextColor)),
                        SizedBox(height: size.height * 0.015),
                        const Text("Your personal interest will be used for customization of possible community service activities recommendation. ", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
                        SizedBox(height: size.height * 0.015),
                        //Add the category preference selection
                        SingleChildScrollView(
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(), // Disable scrolling of the inner ListView
                            itemCount: allCategories.length,
                            itemBuilder: (context, index) {
                              String category = allCategories[index];
                              bool isSelected = selectedPreferences.contains(category);

                              return ListTile(
                                title: Text(category, style: const TextStyle(color: kPrimaryColor, fontFamily: 'Poppins',
                                       fontSize: 14, fontWeight: FontWeight.normal)),
                                trailing: Switch(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      isSelected = value;
                                      if (isSelected) {
                                        selectedPreferences.add(category);
                                      } else {
                                        selectedPreferences.remove(category);
                                      }
                                    });
                                  },
                                  activeColor: Colors.green,
                                  inactiveTrackColor: descColor,
                                ),
                              );
                            },
                          ),
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
                                    showDoubleConfirmDialog(context).then((confirmed) {
                                      if (confirmed) {
                                        updatePersonalInterest(context, selectedPreferences, widget.userID);
                                      }
                                    });
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
            'Are you sure you want to update your preferences?',
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


