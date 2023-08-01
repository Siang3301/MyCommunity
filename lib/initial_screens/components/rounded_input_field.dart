
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
      height: size.height * 0.10,
      padding: const EdgeInsets.fromLTRB(30,2,30,2),
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!EmailValidator.validate(value)){
            return 'Please enter a valid email';
          }
          return null;
        },
        keyboardType: TextInputType.emailAddress,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: "Email",
          labelStyle: TextStyle(color: Color(0xFF979797), fontFamily: "SourceSansPro"),
        ),
      ),
    );
  }
}

