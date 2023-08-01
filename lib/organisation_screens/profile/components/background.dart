import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class Background extends StatelessWidget {
  final Widget child;

  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: size.height,
      color: secBackColor,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          child,
        ],
      ),
    );
  }
}
