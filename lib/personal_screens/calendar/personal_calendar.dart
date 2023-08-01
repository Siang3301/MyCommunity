import 'package:flutter/material.dart';
import 'package:mycommunity/personal_screens/calendar/components/body.dart';

class PersonalCalendarScreen extends StatelessWidget {
  const PersonalCalendarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PersonalCalendarBody(),
    );
  }
}
