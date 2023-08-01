import 'package:mycommunity/services/constants.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/initial_screens/Login/login_screen.dart';
import 'package:mycommunity/initial_screens/Signup/personal/components/background.dart';
import 'package:mycommunity/initial_screens/components/already_have_an_account_acheck.dart';
import 'package:mycommunity/initial_screens/signup/organisation/components/body_2.dart';
import 'package:mycommunity/initial_screens/signup/organisation/components/rounded_org_name_field.dart';
import 'package:mycommunity/initial_screens/signup/organisation/components/rounded_type_field.dart';
import 'package:mycommunity/initial_screens/signup/personal/components/body.dart';


class OrganisationSignupBody extends StatefulWidget{
  const OrganisationSignupBody({Key? key}) : super(key: key);

  @override
  _SignupBody createState() => _SignupBody();
}


class _SignupBody extends State<OrganisationSignupBody> {
  final _formKey = GlobalKey<FormState>();
  String error = '';

  // text field state
  String orgName = '';
  String orgType = '';

  void _handleCategorySelected(String cat) {
    setState(() {
      orgType = cat;
    });
  }

  @override
  Widget build(BuildContext context) {
    //final auth = Provider.of(context)!.auth;
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
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => const PersonalSignupBody()));
                          },
                          child:Container(
                            margin: const EdgeInsets.only(left: 25.0, right: 20.0),
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
                                    "assets/icons/profile.png",
                                    height: 30,
                                    width: 30,
                                    fit: BoxFit.contain,
                                    color: kPrimaryColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container (
                                  child: const Text(
                                    "Personal", style: TextStyle(fontFamily: "Raleway", fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryColor),
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

                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 20.0, right: 30.0),
                            padding: const EdgeInsets.all(5),
                            height: size.height * 0.08,
                            decoration: BoxDecoration(
                                color: kPrimaryColor,
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
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  child: const Text(
                                    "Organisation", style: TextStyle(fontFamily: "Raleway", fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
            const Text("Step 1 of 3: Organisation profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Raleway")),
            SizedBox(height: size.height * 0.03),
            const Text("Your organisation name and type will be \n used to  identify  your community service.", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro")),
            SizedBox(height: size.height * 0.03),
            RoundedOrgNameField(
              onChanged: (value) {
                setState(() {
                  orgName = value.trim();
                });
              },
            ),
            RoundedTypeField(
              onCategorySelected: _handleCategorySelected,
            ),
            SizedBox(height: size.height * 0.02),
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
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => OrganisationSignupBody_2(orgName: orgName, orgType: orgType)));
                    }
                  },
                  child: const Text(
                    "NEXT", style: TextStyle(fontFamily: "Raleway", fontSize: 14, color: Colors.white),
                  ),
                )
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



