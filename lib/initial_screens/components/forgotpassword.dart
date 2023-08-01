import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class ForgotPassword extends StatelessWidget {
  final Function()? press;
  const ForgotPassword({
    Key? key,
    required this.press,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(width: size.width * 0.09),
        GestureDetector(
          onTap: press,
          child: const Text(
            "Forgot Password?",
            style: TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: "SourceSansPro"
            ),
          ),
        )
      ],
    );
  }
}
