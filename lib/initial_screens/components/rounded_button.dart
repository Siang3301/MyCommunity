import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final Function()? press;
  // ignore: prefer_typing_uninitialized_variables
  final textColor;
  const RoundedButton({
    Key? key,
    required this.text,
    required this.press,

    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: size.width * 0.80,
      child: ClipRRect(
        child: newOutlinedButton(),
      ),
    );
  }

  //Used:ElevatedButton as FlatButton is deprecated.
  //Here we have to apply customizations to Button by inheriting the styleFrom
  Widget newOutlinedButton() {
    return OutlinedButton(
      onPressed: press,
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(width: 1.0, color: kPrimaryColor),
          backgroundColor: kPrimaryColor),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 14, fontFamily: 'Raleway', fontWeight: FontWeight.bold),
      ),
    );
  }
}
