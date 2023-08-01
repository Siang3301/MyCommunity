import 'package:flutter/material.dart';
import 'package:mycommunity/organisation_screens/campaign/components/body.dart';

class OrganisationCampaignScreen extends StatelessWidget {
  const OrganisationCampaignScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: OrganisationCampaignBody(),
    );
  }
}
