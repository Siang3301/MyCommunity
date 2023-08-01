import 'package:cloud_firestore/cloud_firestore.dart';

class Campaign {
  String title;
  String description;
  String category;
  DateTime dateTimeStart;
  DateTime dateTimeEnd;
  DateTime completeTime;
  String volunteer;
  String currentVolunteers;
  String imageUrl;
  String address;
  String locationLink;
  GeoPoint selectedLocation;
  String volunteeringDetail;
  String message;
  double geoFenceRadius;
  String organizerID;
  bool isCompleted;
  bool isArchived;
  List<dynamic> joinedUserIds;

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
    required this.isArchived,
    required this.joinedUserIds,
    required this.completeTime
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
      isArchived: data['is_archived'],
      joinedUserIds: data['joinedUserIds'],
      completeTime: data['complete_time'] != null ? data['complete_time'].toDate() : DateTime.now(),
    );
  }

  // Convert Campaign object to a JSON format
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'date_time_start': dateTimeStart,
      'date_time_end': dateTimeEnd,
      'maxVolunteers': volunteer,
      'currentVolunteers': currentVolunteers,
      'image_url': imageUrl,
      'address': address,
      'location_link': locationLink,
      'selected_location': selectedLocation,
      'volunteering_detail': volunteeringDetail,
      'message': message,
      'geofence_radius': geoFenceRadius,
      'organizerID': organizerID,
      'is_completed': isCompleted,
      'joinedUserIds': joinedUserIds,
      'is_archived': isArchived, // Include the is_archived attribute
      'complete_time': completeTime
    };
  }
}