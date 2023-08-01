import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  String title;
  String description;
  String category;
  DateTime dateTimeStart;
  DateTime dateTimeEnd;
  String volunteer;
  String currentVolunteers;
  String imageUrl;
  String address;
  String locationLink;
  GeoPoint selectedLocation;
  String volunteeringDetail;
  String message;
  double geoFenceRadius;
  List<dynamic> numUsersPromoted;
  String organizerID;
  bool isCompleted;

  Campaign({
    required this.title,
    required this.description,
    required this.category,
    required this.dateTimeStart,
    required this.dateTimeEnd,
    required this.volunteer,
    required this.currentVolunteers,
    required this.imageUrl,
    required this.address,
    required this.locationLink,
    required this.selectedLocation,
    required this.volunteeringDetail,
    required this.message,
    required this.geoFenceRadius,
    required this.organizerID,
    required this.isCompleted,
    required this.numUsersPromoted
  });

  factory Campaign.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    return Campaign(
      title: data['title'],
      description: data['description'],
      category: data['category'],
      dateTimeStart: data['date_time_start'].toDate(),
      dateTimeEnd: data['date_time_end'].toDate(),
      volunteer: data['maxVolunteers'],
      currentVolunteers: data['currentVolunteers'],
      imageUrl: data['image_url'],
      address: data['address'],
      locationLink: data['location_link'],
      selectedLocation: data['selected_location'],
      volunteeringDetail: data['volunteering_detail'],
      message: data['message'],
      geoFenceRadius: (data['geofence_radius'] as num).toDouble(),
      organizerID: data['organizerID'],
      isCompleted: data['is_completed'],
      numUsersPromoted: data['users_promoted'] ?? [],
    );
  }
}