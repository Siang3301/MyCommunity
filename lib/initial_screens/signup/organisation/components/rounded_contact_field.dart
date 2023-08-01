import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:string_validator/string_validator.dart';

class RoundedContactField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const RoundedContactField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedContactField> createState() => _RoundedContactField();
}

class _RoundedContactField extends State<RoundedContactField> {
  IconData? get icon => Icons.person;
  bool isNum = false;
  RegExp _numeric = RegExp(r'^-?[0-9]+$');

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.11,
      padding: const EdgeInsets.fromLTRB(30,2,30,2),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
      ),
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your contact';
          }
          isNum = isNumeric(value);
          if (isNum == false){
            return 'Contact number must not contain dash or alphabet!';
          }
          if (value.length > 20) {
            return 'Contact number must not more than 20 digits!';
          }
          return null;
        },
        keyboardType: TextInputType.text,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Contact Number",
          hintText: "0123456789",
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  bool isNumeric(String age) {
    return _numeric.hasMatch(age);
  }
}