import 'package:flutter/material.dart';
import 'package:mycommunity/initial_screens/Login/login_screen.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "MyCommunity",
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
            ),
            const SizedBox(
              height: 32,
            ),
            const Text(
              "Make some impact to your community now!",
              style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 20,
                color: mainTextColor
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Center(
            child: Image.asset(
                "assets/images/community_back.png",
                height: 245,
              ),
            ),
            const SizedBox(
              height: 85,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const Text(
                  "Already have an Account ? ",
                  style: TextStyle(color: kPrimaryColor, fontFamily: "SourceSansPro"),
                ),
                GestureDetector(
                  onTap: () async {
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('seenOnboarding', true);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const LoginScreen();
                        },
                      ),
                    );
                  },
                  child: const Text(
                    "Sign In",
                    style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: "SourceSansPro"
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}