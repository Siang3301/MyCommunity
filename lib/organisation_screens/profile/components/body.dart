import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mycommunity/initial_screens/welcome/welcome_screen.dart';
import 'package:mycommunity/organisation_screens/profile/campaign_archive.dart';
import 'package:mycommunity/organisation_screens/profile/components/account_management.dart';
import 'package:mycommunity/organisation_screens/profile/components/pie_chart.dart';
import 'package:mycommunity/organisation_screens/profile/components/write_feedback.dart';
import 'package:mycommunity/organisation_screens/profile/model/user.dart';
import 'package:mycommunity/organisation_screens/profile/organisation_preview.dart';
import 'package:mycommunity/services/auth_service.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/organisation_screens/profile/components/background.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';


class OrganisationProfileBody extends StatefulWidget{
  const OrganisationProfileBody({Key? key}) : super(key: key);

  @override
  _OrganisationProfileBody createState() => _OrganisationProfileBody();
}

class _OrganisationProfileBody extends State<OrganisationProfileBody>
    with TickerProviderStateMixin{

  File? _image;
  final _formKey = GlobalKey<FormState>();
  TabController? _tabController;
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController!.removeListener(_handleTabSelection);
    _tabController!.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {
      selectedTabIndex = _tabController!.index;
    });
  }

  void _getImage() async {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;

    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Crop the image
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1), // Set desired aspect ratio
        compressQuality: 70, // Set desired quality (0 - 100)
        maxWidth: 500, // Set maximum width
        maxHeight: 500, // Set maximum height
      );

      bool confirmed = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Update User Image', style: TextStyle(fontFamily: 'Raleway')),
            content: const Text('Are you sure you want to update your user image?', style: TextStyle(fontFamily: 'Raleway')),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel', style: TextStyle(fontFamily: 'Raleway')),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Update', style: TextStyle(fontFamily: 'Raleway')),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (confirmed) {
        if (croppedFile != null) {
          File newFile = File(croppedFile.path);
          setState(() {
            _image = newFile;
          });

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Dialog(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(),
                          SizedBox(width: 16.0),
                          Text('Uploading image...', style: TextStyle(fontFamily: 'Raleway')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );

          final FirebaseStorage storage = FirebaseStorage.instance;
          final String userId = auth.getCurrentUID();
          final String imageFilename = '$userId.png';
          final Reference storageRef = storage.ref().child('user_images/$imageFilename');
          final UploadTask uploadTask = storageRef.putFile(_image!);
          final TaskSnapshot downloadUrl = await uploadTask.whenComplete(() {});

          auth.getUser()?.updatePhotoURL(await downloadUrl.ref.getDownloadURL());
          final imageUrl = await downloadUrl.ref.getDownloadURL();

          // Update user image in Firebase
          DocumentReference userRef = FirebaseFirestore.instance.collection('users_data').doc(userId);
          await userRef.update({
            'imageUrl': imageUrl,
          });

          Navigator.of(context).pop(); // Close the loading dialog
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        appBar : AppBar(
          centerTitle: false,
          title:  const Text("My Profile Dashboard", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
         backgroundColor: Colors.white,
         bottomOpacity: 0.0,
         elevation: 0.0,
        actions: <Widget>[
          InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => OrganisationProfilePreview(userId: auth.getCurrentUID())));
              },
              child:
              auth.getUser()?.photoURL == null || auth.getUser()?.photoURL == "null" || auth.getUser()?.photoURL == ""
                  ? Container( margin: const EdgeInsets.only(right: 15), child:Icon(Icons.account_circle_rounded, color: kPrimaryColor, size: 26))
                  : Container(
                margin: const EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryColor, width: 1),
                ),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(auth.getUser()?.photoURL as String),
                  radius: 12,
                ),
              )
          ),
          ],
      ),
      body: Form(
        key: _formKey,
        child:   Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(top:20),
            color: mainBackColor,
            child: Column(
              children: [
                GestureDetector(
                    onTap: _getImage,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          child:CircleAvatar(
                              radius: 65,
                              backgroundColor: secBackColor,
                              backgroundImage: _image != null
                                  ? FileImage(_image!) as ImageProvider<Object>?
                                  : auth.getUser()?.photoURL == "" || auth.getUser()?.photoURL == null || auth.getUser()?.photoURL == "null"
                                  ? const CachedNetworkImageProvider("https://firebasestorage.googleapis.com/v0/b/geofencing-community.appspot.com/o/default%2FDefault-Account-Icon-03bnfc3-300x300.png?alt=media&token=08320d63-ea83-4e07-8c85-f53c2c01647b")
                                  : CachedNetworkImageProvider(auth.getUser()?.photoURL as String)
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30)
                            ),
                            child: IconButton(
                              icon: Icon(Icons.edit, color: kPrimaryColor),
                              onPressed: _getImage,
                            ),
                          ),
                        ),
                      ],
                    )
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(left: 15, right: 15),
                  child:FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      auth.getUser()?.displayName ?? '',
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: mainTextColor,
                          fontFamily: 'Raleway'
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: 15, right: 15),
                  child:FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      auth.getUser()?.email ?? '',
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                          color: mainTextColor,
                          fontFamily: 'Raleway'
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: orgMainColor,
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  indicatorPadding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    Container(
                      child: const Tab(
                        child: Text(
                          'About',
                          style: TextStyle(fontFamily: 'Raleway', fontSize: 16, fontWeight: FontWeight.bold, color: mainTextColor),
                        ),
                      ),
                    ),
                    Container(
                      child: const Tab(
                        child: Text(
                          'Dashboard',
                          style: TextStyle(fontFamily: 'Raleway', fontSize: 16, fontWeight: FontWeight.bold, color: mainTextColor),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                  color: secBackColor,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // About Tab
                      SingleChildScrollView(
                        child:Container(
                          padding: EdgeInsets.only(bottom: 25),
                          color: secBackColor,
                          child: Container(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: 5),
                                  Container(
                                    width: size.width * 0.80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: 15),
                                          child:  Icon(Icons.person_rounded, color: mainTextColor),
                                        ),
                                        const Text("Account Management", style: TextStyle(fontFamily: 'Raleway', fontSize: 15, color: mainTextColor)),
                                        IconButton(
                                          icon: Icon(Icons.navigate_next, color: mainTextColor),
                                          onPressed:(){
                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => AccountManagement(userID: auth.getCurrentUID())));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Container(
                                    width: size.width * 0.80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: 15),
                                          child:  Icon(Icons.archive_rounded, color: mainTextColor),
                                        ),
                                        const Text("Archive Space", style: TextStyle(fontFamily: 'Raleway', fontSize: 15, color: mainTextColor)),
                                        IconButton(
                                          icon: Icon(Icons.navigate_next, color: mainTextColor),
                                          onPressed:(){
                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ArchiveSpace()));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  Container(
                                    width: size.width * 0.80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(left: 15),
                                          child:  Icon(Icons.feedback_rounded, color: mainTextColor),
                                        ),
                                        const Text("User Feedback", style: TextStyle(fontFamily: 'Raleway', fontSize: 15, color: mainTextColor)),
                                        IconButton(
                                          icon: Icon(Icons.navigate_next, color: mainTextColor),
                                          onPressed:(){
                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => WriteFeedback(userID: auth.getCurrentUID())));
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Container(
                                    alignment: Alignment.bottomRight,
                                    padding: EdgeInsets.all(20),
                                    child: TextButton.icon(
                                      onPressed: () async {
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
                                                    Text('Logging out...', style: TextStyle(fontFamily: 'Raleway')),
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
                                      icon: Icon(Icons.logout, color: mainTextColor),
                                      label: const Text(
                                        "Logout",
                                        style: TextStyle(fontFamily: "Raleway", fontSize: 15, color: mainTextColor),
                                      ),
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              )
                          ),
                        ),
                      ),
                      // Dashboard Tab
                      SingleChildScrollView(
                        child: Container(
                          color: secBackColor,
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                stream: FirebaseFirestore.instance
                                    .collection('users_data')
                                    .doc(auth.getCurrentUID())
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    Organisation user = Organisation.fromFirestore(snapshot.data!);
                                    Map<String, dynamic>? userData = snapshot.data!.data();
                                    user.totalCampaignOrganized = userData?['total_campaign_organized'] ?? 0;
                                    user.totalVolunteerAccumulated = userData?['total_volunteer_accumulated'] ?? 0;
                                    user.totalVolunteerRequired = userData?['total_volunteer_required'] ?? 0;

                                    final data = [
                                      ChartData('Accumulated', user.totalVolunteerAccumulated, color: Colors.lightBlueAccent),
                                      ChartData('Required', user.totalVolunteerRequired, color: orgMainColor),
                                    ];

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                              width: size.width * 0.25,
                                              height: 95,
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: orgMainColor.withOpacity(0.1),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: orgMainColor.withOpacity(0.1),
                                                      offset: Offset(0, 2),
                                                      blurRadius: 4,
                                                      spreadRadius: 2
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'Total Campaigns Organized: ',
                                                    style: TextStyle(fontSize: 10, fontFamily: 'Poppins', color: orgMainColor, fontWeight: FontWeight.bold),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    user.totalCampaignOrganized.toString(),
                                                    style: TextStyle(fontSize: 16, fontFamily: 'Poppins', color: orgMainColor, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: size.width * 0.25,
                                              height: 95,
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: orgMainColor.withOpacity(0.1),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: orgMainColor.withOpacity(0.1),
                                                      offset: Offset(0, 2),
                                                      blurRadius: 4,
                                                      spreadRadius: 2
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Total \nVolunteer\nRequired: ',
                                                    style: TextStyle(fontSize: 10, fontFamily: 'Poppins', color: orgMainColor, fontWeight: FontWeight.bold),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Center(
                                                      child:Text(
                                                        user.totalVolunteerRequired.toString(),
                                                        style: TextStyle(fontSize: 16, fontFamily: 'Poppins', color: orgMainColor, fontWeight: FontWeight.bold),
                                                      )
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              width: size.width * 0.25,
                                              height: 95,
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: orgMainColor.withOpacity(0.1),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: orgMainColor.withOpacity(0.1),
                                                      offset: Offset(0, 2),
                                                      blurRadius: 4,
                                                      spreadRadius: 2
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                children: [
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      'Total \nVolunteer \nAccumulated: ', maxLines: 3, overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(fontSize: 10, fontFamily: 'Poppins', color: orgMainColor, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    user.totalVolunteerAccumulated.toString(),
                                                    style: TextStyle(fontSize: 16, fontFamily: 'Poppins', color: orgMainColor, fontWeight: FontWeight.bold),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 10),
                                            DonutChartWidget(data: data)
                                          ],
                                        )
                                      ],
                                    );
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    return CircularProgressIndicator();
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                   ),
                  )
                ),
              ],
            )
        ),
     )
    );
  }
}





