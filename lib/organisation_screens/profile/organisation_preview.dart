import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mycommunity/organisation_screens/profile/components/pie_chart.dart';
import 'package:mycommunity/organisation_screens/profile/model/user.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';


class OrganisationProfilePreview extends StatefulWidget{
  final String userId;
  const OrganisationProfilePreview({Key? key, required this.userId}) : super(key: key);

  @override
  _OrganisationProfilePreview createState() => _OrganisationProfilePreview();
}

class _OrganisationProfilePreview extends State<OrganisationProfilePreview> {
  File? _image;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
    final defaultURL = "https://firebasestorage.googleapis.com/v0/b/geofencing-community.appspot.com/o/default%2FDefault-Account-Icon-03bnfc3-300x300.png?alt=media&token=08320d63-ea83-4e07-8c85-f53c2c01647b";
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users_data')
          .doc(widget.userId)
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

          return Scaffold(
              backgroundColor: secBackColor,
              appBar : AppBar(
                centerTitle: true,
                leading: const BackButton(color: kPrimaryColor),
                title: auth.getCurrentUID() == widget.userId ?
                const Text("My Organisation Profile", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor))
                : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${user.orgName}'s Profile",
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
                backgroundColor: Colors.white,
                bottomOpacity: 0.0,
                elevation: 0.0,
              ),
              body: Align(
                  alignment: Alignment.center,
                  child: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: mainBackColor,
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
                      child: SingleChildScrollView(
                        child: Container(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                const SizedBox(height: 15),
                                auth.getCurrentUID() == widget.userId ?
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
                                          bottom: 0,
                                          right: 0,
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
                                ):
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey, width: 1),
                                  ),
                                  child:CircleAvatar(
                                    radius: 65,
                                    backgroundColor: secBackColor,
                                    backgroundImage: user.imageUrl == "" || user.imageUrl == null || user.imageUrl == "null"
                                        ? CachedNetworkImageProvider("https://firebasestorage.googleapis.com/v0/b/geofencing-community.appspot.com/o/default%2FDefault-Account-Icon-03bnfc3-300x300.png?alt=media&token=08320d63-ea83-4e07-8c85-f53c2c01647b")
                                        : CachedNetworkImageProvider(user.imageUrl),
                                  )
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: EdgeInsets.only(left: 15, right: 15),
                                  child:FittedBox(
                                    fit: BoxFit.contain,
                                    child: Text(
                                      user.orgName,
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
                                      user.orgType,
                                      maxLines: 1,
                                      style: const TextStyle(
                                          fontSize: 15,
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
                                      user.email,
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
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "${user.city}, ${user.state}",
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontStyle: FontStyle.italic,
                                        color: mainTextColor,
                                        fontFamily: 'Raleway'
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.contact,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                      color: mainTextColor,
                                      fontFamily: 'Raleway'
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 10),
                                    Text("- Organisation Contribution -", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: orgMainColor)),
                                    SizedBox(height: 10),
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
                                    SizedBox(height: 5),
                                    Padding(
                                     padding: const EdgeInsets.only(top:5, left: 15, right: 15, bottom: 10),
                                     child:Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 10),
                                        DonutChartWidget(data: data)
                                      ],
                                    )
                                    )
                                  ],
                                )
                              ],
                            )
                        ),
                      )
                  ))
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Container(height: size.height*0.5, alignment: Alignment.center, child:CircularProgressIndicator());
        }
      },
    );

  }
}





