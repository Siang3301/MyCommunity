import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class Background extends StatelessWidget {
  final Widget child;

  Background({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
        width: size.width,
        height: size.height,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              child,
            ],
          ),
        )
    );
  }
}
