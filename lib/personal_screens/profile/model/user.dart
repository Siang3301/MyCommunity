import 'package:cloud_firestore/cloud_firestore.dart';

class Personal {
  String name;
  String ic;
  String age;
  String contact;
  String address;
  String city;
  String postal;
  String state;
  String imageUrl;
  List<dynamic> preferences;
  int totalCampaignParticipated = 0;
  int totalEventParticipated = 0;
  int totalVolunteerHours = 0;
  int totalVolunteerMinutes = 0;
  int totalEventOrganized = 0;
  String email = "";

  Personal({
    required this.name,
    required this.ic,
    required this.age,
    required this.contact,
    required this.address,
    required this.city,
    required this.postal,
    required this.state,
    required this.imageUrl,
    required this.preferences
  });

  factory Personal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    return Personal(
      name: data['username'],
      ic: data['identification_number'],
      age: data['age'],
      contact: data['contact'],
      address: data['address'],
      city: data['city'],
      postal: data['postal'],
      state: data['state'],
      imageUrl: data['imageUrl'] ?? '',
      preferences: data['preferences']
    );
  }
}