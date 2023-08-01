import 'package:flutter/material.dart';

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
                color: Colors.white,
                height: size.height*0.05,
                padding: const EdgeInsets.only(left: 20, top: 10),
                width: size.width,
              ),
              child,
            ],
          ),
    );
  }
}
