import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:intl/intl.dart';

String getCurrentDateTime() {
  DateTime now = DateTime.now();
  DateFormat dateFormat = DateFormat('dd/MM/yy');
  DateFormat timeFormat = DateFormat('h:mm a');

  String formattedDate = dateFormat.format(now);
  String formattedTime = timeFormat.format(now);

  return '$formattedDate\n$formattedTime';
}

class Background extends StatelessWidget {
  final Widget child;
  final String username;
  bool home = false;

  Background({
    Key? key,
    required this.child,
    required this.username,
    required this.home
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
          home == true ?
          Container(
            color: Colors.white,
            height: size.height*0.10,
            width: size.width,
            padding: const EdgeInsets.only(left: 20, top: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: size.width*0.7,
                      child: const Text(
                        "Welcome Back,", textAlign: TextAlign.start,
                        style : const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainTextColor, fontFamily: "Raleway"
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    SizedBox(
                      width: size.width*0.7,
                      child: Text(
                        username, textAlign: TextAlign.start, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style : const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: mainTextColor, fontFamily: "Raleway"
                        ),
                      ),
                    )
                  ],
                ),
                Expanded(
                  child: Text(
                    getCurrentDateTime(), textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontFamily: 'Poppins', fontStyle: FontStyle.italic, color: kSecondaryColor, fontWeight: FontWeight.bold),
                  )
                )
              ],
            )
          ) : SizedBox(),
          child,
        ],
       ),
      )
    );
  }
}
