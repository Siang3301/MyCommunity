import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedInputField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  
  const RoundedInputField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedInputField> createState() => _RoundedInputField();
}

class _RoundedInputField extends State<RoundedInputField> {
  IconData? get icon => Icons.mail;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.11,
      padding: const EdgeInsets.fromLTRB(30,2,30,2),
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!EmailValidator.validate(value)){
            return 'Please enter a valid email';
          }
          if (value.length > 255) {
            return 'Your email cannot be accepted, too long!';
          }
          return null;
        },
        keyboardType: TextInputType.emailAddress,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          enabledBorder:  OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border:  OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Email",
          hintText: "Email Address",
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }
}

