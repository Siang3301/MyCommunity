import 'package:flutter/material.dart';
import 'package:mycommunity/personal_screens/activity/components/body.dart';

class PersonalActivityScreen extends StatelessWidget {
  const PersonalActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: PersonalActivityBody(),
    );
  }
}
