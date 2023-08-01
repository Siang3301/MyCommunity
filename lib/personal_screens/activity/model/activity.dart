import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  campaign,
  event,
}

class Activity {
  final String id;
  String? name;
  String? description;
  String? organizerID;
  String? organizerName;
  bool? activityStatus;
  bool? isArchived;
  List<dynamic>? joinedUserIds;
  final ActivityType type;
  final Timestamp registerAt;
  DateTime? date_time_start;
  DateTime? date_time_end;

  Activity({
    required this.id,
    required this.type,
    required this.registerAt,
  });

  factory Activity.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final typeString = data['activityType'] as String;
    ActivityType type;
    if (typeString == 'campaign') {
      type = ActivityType.campaign;
    } else if (typeString == 'event') {
      type = ActivityType.event;
    } else {
      throw Exception('Unknown activity type: $typeString');
    }

    return Activity(
      id: data['activityId'],
      type: type,
      registerAt: data['registerAt'] as Timestamp,
    );
  }
}