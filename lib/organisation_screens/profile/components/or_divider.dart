import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class CustomDivider extends StatelessWidget {
  final String text;
  const CustomDivider({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(vertical: size.height * 0.01),
      width: size.width * 0.9,
      child: Row(
        children: <Widget>[
          buildDivider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 7),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF707070),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          buildDivider(),
        ],
      ),
    );
  }

  Expanded buildDivider() {
    return const Expanded(
      child: Divider(
        color: Color(0xFF707070),
        thickness: 1,
        height: 10,
      ),
    );
  }
}
