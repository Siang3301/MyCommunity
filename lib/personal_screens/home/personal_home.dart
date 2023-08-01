import 'package:flutter/material.dart';
import 'package:mycommunity/personal_screens/home/components/body.dart';

class PersonalHomeScreen extends StatelessWidget {
  const PersonalHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PersonalHomeBody(),
    );
  }
}
