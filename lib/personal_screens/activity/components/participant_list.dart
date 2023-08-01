import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/personal_screens/profile/profile_preview.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:intl/intl.dart';

class ParticipantList extends StatefulWidget {
  final String activityId;
  final String activityType;

  ParticipantList({
    required this.activityId,
    required this.activityType,
  });

  @override
  _ParticipantListState createState() => _ParticipantListState();
}

class _ParticipantListState extends State<ParticipantList> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _participantStream;
  final defaultURL = "https://firebasestorage.googleapis.com/v0/b/geofencing-community.appspot.com/o/default%2FDefault-Account-Icon-03bnfc3-300x300.png?alt=media&token=08320d63-ea83-4e07-8c85-f53c2c01647b";

  @override
  void initState() {
    super.initState();
    _participantStream = FirebaseFirestore.instance
        .collection(widget.activityType == "campaigns" ? "campaigns" : "events")
        .doc(widget.activityId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: mainBackColor,
      appBar : AppBar(
        leading: const BackButton(color: kPrimaryColor),
        centerTitle: true,
        title:  const Text("Details", style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.bold, fontSize: 18, color: kPrimaryColor)),
        backgroundColor: Colors.white,
        bottomOpacity: 0.0,
        elevation: 0.0,
      ),
      body:SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _participantStream,
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return Container(
                  height: size.height*0.45,
                  alignment: Alignment.bottomCenter,
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.data!.exists) {
                return const Center(
                  child: Text("No data available!", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Raleway', color: mainTextColor)),
                );
              }

              Map<String, dynamic> activityData = snapshot.data!.data()!;
              List<dynamic>? participantIds = activityData['joinedUserIds'];
              final currentVolunteers = activityData['currentVolunteers'];
              final maxVolunteers = activityData['maxVolunteers'];

              if(participantIds == null || participantIds.isEmpty){
                return const Center(
                  child: Text("No participant register to this activity yet!", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Raleway', color: mainTextColor)),
                );
              }

              return ListView.builder(
                itemCount: participantIds.length,
                itemBuilder: (BuildContext context, int index) {
                  String participantId = participantIds[index]['userId'];
                  final displayName = participantIds[index]['displayName'];
                  String imageURL = participantIds[index]['imageURL'];

                  if(imageURL == "null" || imageURL == "" || imageURL == null){
                    imageURL = defaultURL;
                  }

                  return GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalProfilePreview(userId: participantId)));
                    },
                    child:FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users_data')
                          .doc(participantId)
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                        if (userSnapshot.hasError) {
                          return Text('Error: ${userSnapshot.error}');
                        }

                        if (!userSnapshot.hasData) {
                          return Container(
                            height: size.height*0.45,
                            alignment: Alignment.bottomCenter,
                            child: CircularProgressIndicator(),
                          );
                        }

                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users_data')
                              .doc(participantId)
                              .collection('user_activities')
                              .where('activityId', isEqualTo: widget.activityId)
                              .snapshots()
                              .map((querySnapshot) => querySnapshot.docs.first),
                          builder: (BuildContext context,
                              AsyncSnapshot<DocumentSnapshot> activitySnapshot) {
                            if (activitySnapshot.hasError) {
                              return Text('Error: ${activitySnapshot.error}');
                            }

                            if (!activitySnapshot.hasData) {
                              return Container(
                                height: size.height*0.45,
                                alignment: Alignment.bottomCenter,
                                child: CircularProgressIndicator(),
                              );
                            }

                            Map<String, dynamic> activityData =
                            activitySnapshot.data!.data()! as Map<String, dynamic>;
                            DateTime registerAt = activityData['registerAt'].toDate();

                            if(index == 0) {
                              return Padding(
                                padding: EdgeInsets.all(15),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(15),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            const Text("List of Participants",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontFamily: 'Raleway',
                                                    color: mainTextColor,
                                                    fontWeight: FontWeight.bold)),
                                            Text(
                                              "$currentVolunteers / $maxVolunteers",
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontFamily: 'SourceSansPro',
                                                  color: mainTextColor),
                                            )
                                          ],
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.only(
                                            top: 15,
                                            left: 10,
                                            right: 10,
                                            bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              10.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.5),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                imageURL),
                                          ),
                                          title: Text(displayName,
                                              style: const TextStyle(fontSize: 14,
                                                  fontFamily: 'Raleway',
                                                  color: mainTextColor,
                                                  fontWeight: FontWeight.bold)),
                                          subtitle: Text(
                                              'Registered on: ${DateFormat(
                                                  'dd/MM/yyyy hh:mm a').format(
                                                  registerAt)}',
                                              style: const TextStyle(fontSize: 13,
                                                  fontFamily: 'SourceSansPro',
                                                  color: mainTextColor)),
                                          trailing: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Divider(color: Color(0xFF707070))
                                    ],
                                  ),
                                ),
                              );
                            }else{
                              return Padding(
                                padding: EdgeInsets.only(left:15, right:15),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(
                                            left: 10,
                                            right: 10,
                                            bottom: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              10.0),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.5),
                                              spreadRadius: 1,
                                              blurRadius: 5,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          leading: imageURL == null
                                              ? CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                defaultURL),
                                          )
                                              : CircleAvatar(
                                            backgroundImage: NetworkImage(
                                                imageURL),
                                          ),
                                          title: Text(displayName,
                                              style: const TextStyle(fontSize: 14,
                                                  fontFamily: 'Raleway',
                                                  color: mainTextColor,
                                                  fontWeight: FontWeight.bold)),
                                          subtitle: Text(
                                              'Registered on: ${DateFormat(
                                                  'dd/MM/yyyy hh:mm a').format(
                                                  registerAt)}',
                                              style: const TextStyle(fontSize: 13,
                                                  fontFamily: 'SourceSansPro',
                                                  color: mainTextColor)),
                                          trailing: Text(
                                            '${index + 1}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Divider(color: Color(0xFF707070))
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    )
                  );
                },
              );
            },
          ),
        ),
    );
  }
}