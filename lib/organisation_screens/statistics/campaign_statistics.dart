import 'package:flutter/material.dart';
import 'package:mycommunity/organisation_screens/statistics/components/body.dart';

class OrganisationCampaignStatisticsScreen extends StatelessWidget {
  const OrganisationCampaignStatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: OrganisationCampaignStatisticsBody(),
    );
  }
}
