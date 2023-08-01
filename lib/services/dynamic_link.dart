import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mycommunity/personal_screens/home/components/campaign_detail.dart';
import 'package:mycommunity/personal_screens/home/components/event_detail.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class DynamicLinkProvider{

  Future<String> createEventLink(String activityId, String eventName, String eventAddress, String organizerName) async {
    final String url = "https://com.geofencing.community.mycommunity/event?eventId=$activityId";

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      androidParameters:
        const AndroidParameters(packageName: "com.geofencing.community.mycommunity", minimumVersion: 0),
      link: Uri.parse(url),
      uriPrefix: "https://mycommunity2023.page.link"
    );

    final FirebaseDynamicLinks link = FirebaseDynamicLinks.instance;
    String text = "Check out this personal individual event!";
    String name = "Event Name: $eventName";
    String address = "Event Address: $eventAddress";
    String organizer = "Created by: $organizerName";
    final eventLink = await link.buildShortLink(parameters);
    final eventShortLink = eventLink.shortUrl.toString();
    String eventLinkText = "Link: $eventShortLink";
    final String value = "$text\n\n$name\n$address\n$organizer\n\n$eventLinkText";
    return value;
  }

  Future<String> createCampaignLink(String activityId, String campaignName, String campaignAddress, String organizerName) async {
    final String url = "https://com.geofencing.community.mycommunity/campaign?campaignId=$activityId";

    final DynamicLinkParameters parameters = DynamicLinkParameters(
        androidParameters:
        const AndroidParameters(packageName: "com.geofencing.community.mycommunity", minimumVersion: 0),
        link: Uri.parse(url),
        uriPrefix: "https://mycommunity2023.page.link"
    );

    final FirebaseDynamicLinks link = FirebaseDynamicLinks.instance;
    String text = "Check out this exciting community campaign!";
    String name = "Campaign Name: $campaignName";
    String address = "Campaign Address: $campaignName";
    String organizer = "Organized by: $organizerName";
    final campaignLink = await link.buildShortLink(parameters);
    final campaignShortLink = campaignLink.shortUrl.toString();
    String campaignLinkText = "Link: $campaignShortLink";
    final String value = "$text\n\n$name\n$address\n$organizer\n\n$campaignLinkText";
    return value;
  }

  bool isUserSignedIn() {
    User? user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  void initDynamicLink() async {
    final instanceLink = await FirebaseDynamicLinks.instance.getInitialLink();

    bool isSignedIn = isUserSignedIn();
    if (isSignedIn) {
      if (instanceLink != null) {
        final Uri activityLink = instanceLink.link;

        // Extract the parameters from the deep link
        final String? campaignId = activityLink.queryParameters['campaignId'];
        final String? eventId = activityLink.queryParameters['eventId'];

        // Check if the app is already running and navigate to the appropriate screen
        if (campaignId != null) {
          // App is running and the deep link contains a campaignId parameter
          // Navigate to the campaign detail screen with the campaignId
          GlobalVariable.navState.currentState!.push(MaterialPageRoute(builder: (context) => CampaignDetailScreen(campaignID: campaignId)));
        } else if (eventId != null) {
          // App is running and the deep link contains an eventId parameter
          // Navigate to the event detail screen with the eventId
          GlobalVariable.navState.currentState!.push(MaterialPageRoute(builder: (context) => EventDetailScreen(eventID: eventId)));
        }
      }
    }else{
      Fluttertoast.showToast(
        backgroundColor: Colors.grey,
        msg: 'Please sign in to application to view the activity.',
        gravity: ToastGravity.CENTER,
        fontSize: 16.0,
      );
    }
  }

}