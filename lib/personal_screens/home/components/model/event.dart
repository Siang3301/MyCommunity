import 'package:cloud_firestore/cloud_firestore.dart';

class eventInfo {
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String organizerID;
  final String volunteers;
  final GeoPoint selectedLocation;
  String id = "";
  double distance = 0.0;

  eventInfo({
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.organizerID,
    required this.volunteers,
    required this.selectedLocation,
  });

  static eventInfo fromDoc(QueryDocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return eventInfo(
      title: data['title'],
      description: data['description'],
      category: data['category'],
      imageUrl: data['image_url'],
      organizerID: data['organizerID'],
      volunteers: data['maxVolunteers'],
      selectedLocation: data['selected_location'],
    );
  }
}