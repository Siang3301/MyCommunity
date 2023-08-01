import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/initial_screens/components/rounded_button_google.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/initial_screens/Login/login_screen.dart';
import 'package:mycommunity/initial_screens/Signup/personal/components/background.dart';
import 'package:mycommunity/initial_screens/components/or_divider.dart';
import 'package:mycommunity/initial_screens/components/already_have_an_account_acheck.dart';
import 'package:mycommunity/initial_screens/signup/organisation/components/body_3.dart';
import 'package:mycommunity/initial_screens/Signup/organisation/components/rounded_input_field.dart';
import 'package:mycommunity/initial_screens/Signup/organisation/components/rounded_password_field.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';


class OrganisationSignupBody_2 extends StatefulWidget{
  final String orgName, orgType;
  const OrganisationSignupBody_2({Key? key, required this.orgName, required this.orgType}) : super(key: key);

  @override
  _SignupBody createState() => _SignupBody();
}


class _SignupBody extends State<OrganisationSignupBody_2> {
  final _formKey = GlobalKey<FormState>();
  String error = '';

  // text field state
  String email = '';
  String password = '';
  String option = '';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: Form(
        key: _formKey,
        child:Background(
        child: SingleChildScrollView(
          child: Container(
        height: size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 50, right: 225),
            ),
            const Text("Step 2 of 3: Organisation login details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway")),
            SizedBox(height: size.height * 0.03),
            const Text("This details will be used for verification \n purposes in MyCommunity application only.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
            SizedBox(height: size.height * 0.03),
            RoundedInputField(
              onChanged: (value) {
                setState(() {
                  email = value.trim();
                });
              },
            ),
            RoundedPasswordField(
              onChanged: (value) {
                setState(() {
                  password = value.trim();
                });
              },
            ),
            SizedBox(height: size.height * 0.03),
            Container(
                alignment: Alignment.bottomRight,
                width: size.width * 0.25,
                margin: EdgeInsets.only(left: size.width*0.60),
                padding: const EdgeInsets.all(5),
                height: size.height * 0.06,
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  borderRadius: BorderRadius.circular(12.0),
                  shape: BoxShape.rectangle,
                ),
                child:ElevatedButton(
                  onPressed: ()  {
                    if (_formKey.currentState!.validate()) {
                      option = 'email';
                      Navigator.push(context, MaterialPageRoute(builder: (context) => OrganisationSignupBody_3(orgName: widget.orgName, orgType: widget.orgType, email: email, password: password, option: option)));
                    }
                  },
                  child: const Text(
                    "NEXT", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                  ),
                )
            ),

            SizedBox(height: size.height * 0.015),
            const OrDivider(),
            RoundedButtonGoogle(
              text: "CONTINUE WITH GOOGLE",
              press: () async {
                option = "google";
                setState(() {
                });

                await auth.signUpWithGoogle_organisation(context: context, orgName: widget.orgName, orgType: widget.orgType);

                setState(() {
                });
              },
            ),
            Spacer(),
            Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.all(10),
              child: const Text(
                "By signing up you agree with our terms and to receive periodic updates and tips.", textAlign: TextAlign.center,
                style : TextStyle(fontSize: 13, color: mainTextColor, fontFamily: "SourceSansPro"
                ),
              ),
            ),
          ],
        ),
          )
      ),
    )
        )
    );
  }

}



