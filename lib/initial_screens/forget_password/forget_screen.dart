import 'package:flutter/material.dart';
import 'package:mycommunity/initial_screens/forget_password/components/body.dart';

class ForgetScreen extends StatelessWidget {
  const ForgetScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ForgetBody(),
    );
  }
}
