import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:email_validator/email_validator.dart';
import 'package:mycommunity/initial_screens/components/rounded_button_google.dart';
import 'package:mycommunity/initial_screens/Login/login_screen.dart';
import 'package:mycommunity/initial_screens/Signup/personal/components/background.dart';
import 'package:mycommunity/initial_screens/components/or_divider.dart';
import 'package:mycommunity/initial_screens/components/already_have_an_account_acheck.dart';
import 'package:mycommunity/initial_screens/Signup/personal/components/rounded_name_field.dart';
import 'package:mycommunity/initial_screens/Signup/personal/components/rounded_input_field.dart';
import 'package:mycommunity/initial_screens/Signup/personal/components/rounded_password_field.dart';
import 'package:mycommunity/initial_screens/signup/organisation/components/body.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/body_2.dart';
import 'package:mycommunity/widgets/provider_widgets.dart';


class PersonalSignupBody extends StatefulWidget{
  const PersonalSignupBody({Key? key}) : super(key: key);

  @override
  _SignupBody createState() => _SignupBody();
}


class _SignupBody extends State<PersonalSignupBody> {
  final _formKey = GlobalKey<FormState>();

  // text field state
  String email = '';
  String password = '';
  String name = '';
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
             Container(
               margin: const EdgeInsets.only(top: 50, right: 225),
               child: const Text(
               "Sign up as",
               style: TextStyle(color: kPrimaryColor, fontSize: 25, fontFamily: 'Raleway'),
               ),
             ),
            SizedBox(height: size.height * 0.05),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: (){

                        },
                        child:Container(
                        margin: const EdgeInsets.only(left: 25.0, right: 20.0),
                        padding: const EdgeInsets.all(5),
                        height: size.height * 0.08,
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(10.0),
                          shape: BoxShape.rectangle,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Image.asset(
                                "assets/icons/profile.png",
                                height: 30,
                                width: 30,
                                fit: BoxFit.contain,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container (
                              child: const Text(
                                "Personal", style: TextStyle(fontFamily: "Raleway", fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                      )
                    ],
                  ),
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                      onTap: (){
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => const OrganisationSignupBody()));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 20.0, right: 30.0),
                        padding: const EdgeInsets.all(5),
                        height: size.height * 0.08,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.0),
                          shape: BoxShape.rectangle,
                          border: Border.all(color: kPrimaryColor)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Image.asset(
                                "assets/icons/organisation.png",
                                height: 30,
                                width: 30,
                                fit: BoxFit.contain,
                                color: kPrimaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              child: const Text(
                                "Organisation", style: TextStyle(fontFamily: "Raleway", fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryColor),
                              ),
                            ),
                          ],
                        ),
                      )
                      )
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.04),
            const Text("Step 1 of 2: Login details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway")),
            SizedBox(height: size.height * 0.03),
            const Text("This details will be used for verification \n purposes in MyCommunity application only.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
            SizedBox(height: size.height * 0.03),
            RoundedNameField(
              onChanged: (value) {
                setState(() {
                  name = value.trim();
                });
              },
            ),
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
            AlreadyHaveAnAccountCheck(
              login: false,
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const LoginScreen();
                    },
                  ),
                );
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
                    if (_formKey.currentState!.validate() &&
                        EmailValidator.validate(email.trim())) {
                      option = 'email';
                      Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalSignupBody_2(name: name, email: email, password: password, option: option)));
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
              text: "SIGN UP WITH GOOGLE",
                  press: () async {
                    option = "google";
                    setState(() {
                    });

                    await auth.signUpWithGoogle_personal(context: context);

                    setState(() {
                    });
                  },
                ),
            SizedBox(height: size.height * 0.03),
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
      ),
    )
        )
    );
  }

}



