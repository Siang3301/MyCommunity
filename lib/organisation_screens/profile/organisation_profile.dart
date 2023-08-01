import 'package:flutter/material.dart';
import 'package:mycommunity/organisation_screens/profile/components/body.dart';

class OrganisationProfileScreen extends StatelessWidget {
  const OrganisationProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: OrganisationProfileBody(),
    );
  }
}
