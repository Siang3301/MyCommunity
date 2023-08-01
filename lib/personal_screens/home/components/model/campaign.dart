import 'package:cloud_firestore/cloud_firestore.dart';

class campaignInfo {
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final GeoPoint selectedLocation;
  String id = "";
  double distance = 0.0;

  campaignInfo({
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.selectedLocation,
  });

  static campaignInfo fromDoc(QueryDocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>;
    return campaignInfo(
      title: data['title'],
      selectedLocation: data['selected_location'],
      description: data['description'],
      category: data['category'],
      imageUrl: data['image_url'],
    );
  }
}