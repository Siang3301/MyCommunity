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
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: <Widget>[
          Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(10),
            child: const Text(
              "By signing up you agree with our terms and to receive periodic updates and tips.", textAlign: TextAlign.center,
              style : TextStyle(fontSize: 13, color: mainTextColor, fontFamily: "SourceSansPro"
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
