import 'package:cloud_firestore/cloud_firestore.dart';

class Organisation {
  String orgName;
  String orgID;
  String orgType;
  String contact;
  String address;
  String city;
  String postal;
  String state;
  String imageUrl;
  String email;
  int totalCampaignOrganized = 0;
  int totalVolunteerAccumulated = 0;
  int totalVolunteerRequired = 0;

  Organisation({
    required this.orgName,
    required this.orgID,
    required this.orgType,
    required this.contact,
    required this.address,
    required this.city,
    required this.postal,
    required this.state,
    required this.imageUrl,
    required this.email,
  });

  factory Organisation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    return Organisation(
      orgName: data['organisation_name'],
      orgID: data['organisation_ID'],
      orgType: data['organisation_type'],
      contact: data['contact'],
      address: data['address'],
      city: data['city'],
      postal: data['postal'],
      state: data['state'],
      email: data['email'],
      imageUrl: data['imageUrl'] ?? ""
    );
  }
}