import 'package:flutter/material.dart';
import 'package:mycommunity/personal_screens/profile/components/body.dart';

class PersonalProfileScreen extends StatelessWidget {
  const PersonalProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PersonalProfileBody(),
    );
  }
}
