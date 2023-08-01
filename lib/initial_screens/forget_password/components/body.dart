import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/services/auth_service.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:mycommunity/initial_screens/forget_password/components/background.dart';
import 'package:mycommunity/initial_screens/components/rounded_button.dart';
import 'package:mycommunity/initial_screens/forget_password/components/rounded_input_field.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgetBody extends StatefulWidget{
  const ForgetBody({Key? key}) : super(key: key);

  @override
  _ForgetBody createState() => _ForgetBody();
}

class _ForgetBody extends State<ForgetBody> {
  final _formKey = GlobalKey<FormState>();
  String _email = "";

  @override
  Widget build(BuildContext context) {
    //final auth = Provider.of(context)!.auth;
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Container(
          height: size.height,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 110, left: 30),
                      width: size.width * 0.5,
                      child: const Text(
                        "Forget Password",
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 25,
                          color: kPrimaryColor,
                          fontFamily: 'Raleway',
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 110, left: 30),
                        width: size.width * 0.5,
                        child: Image.asset(
                          "assets/icons/resetpassword.png",
                          height: 50,
                          width: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size.height * 0.05),
                const SizedBox(
                  child: Text(
                    " Enter your email address to receive a password reset link",
                    style: TextStyle(
                      fontFamily: "SourceSansPro",
                      fontSize: 14,
                      color: mainTextColor,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.03),
                RoundedInputField(
                  onChanged: (value) {
                    setState(() {
                      _email = value.trim();
                    });
                  },
                ),
                SizedBox(height: size.height * 0.01),
                RoundedButton(
                  text: "SUBMIT",
                  press: () async {
                    if (_formKey.currentState!.validate()) {
                      // Check if the email account exists
                      bool accountExists = await AuthService.checkAccountExists(_email);

                      if (accountExists) {
                        try {
                          AuthService.resetPassword(_email);
                          _showDialog(context);
                        } catch (e) {
                          Fluttertoast.showToast(
                            backgroundColor: Colors.grey,
                            msg: "Failed to reset password. Please try again.",
                            gravity: ToastGravity.CENTER,
                            fontSize: 16.0,
                          );
                        }
                      } else {
                        Fluttertoast.showToast(
                          backgroundColor: Colors.grey,
                          msg: "Account does not exist.",
                          gravity: ToastGravity.CENTER,
                          fontSize: 16.0,
                        );
                      }
                    }
                  },
                ),
                Spacer(),
                Container(
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.all(10),
                  child: const Text(
                    "By resetting password you should reset your \n password within 5 minutes.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: mainTextColor,
                      fontFamily: "SourceSansPro",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: size.width*0.20),
            alignment: Alignment.center,
            child: Container(
              height: size.height*0.45,
              child: Column(
                  children: [
                    SizedBox(height: size.height * 0.02),
                    Image.asset("assets/icons/resetlogo.png", width: 40,height: 40,fit:BoxFit.contain),
                    SizedBox(height: size.height * 0.03),
                    const Text("Email Sent!"),
                    SizedBox(height: size.height * 0.02),
                    const Divider(
                      color: Color(0xFF707070),
                      thickness: 1.0,
                    ),
                    SizedBox(height: size.height * 0.03),
                    Container(
                      margin: const EdgeInsets.all(10),
                      child : const Text(
                        "An email reset link has sent to your inbox, please reset within 1 hour before the link expired, thank you!", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontFamily: "SourceSansPro", color: darkTextColor),
                      ),
                    ),
                    SizedBox(height: size.height * 0.04),
                    Container(
                      width: size.width*0.3,
                      child:TextButton(
                          style: ButtonStyle(
                              padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.all(15)),
                              foregroundColor: MaterialStateProperty.all<Color>(kPrimaryColor),
                              backgroundColor: MaterialStateProperty.all<Color>(kPrimaryColor),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13.0),
                                    side: BorderSide(color: kPrimaryColor),
                                  )
                              )
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                              "Back".toUpperCase(),
                              style: TextStyle(fontSize: 14, fontFamily: "Raleway", color: Colors.white)
                          )
                      ),
                    ),
                  ]
              ),
            )
        );
      },
    );
  }
}





