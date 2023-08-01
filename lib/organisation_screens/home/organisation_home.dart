import 'package:flutter/material.dart';
import 'package:mycommunity/organisation_screens/home/components/body.dart';

class OrganisationHomeScreen extends StatelessWidget {
  const OrganisationHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: OrganisationHomeBody(),
    );
  }
}
