import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:string_validator/string_validator.dart';

class RoundedStateField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const RoundedStateField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedStateField> createState() => _RoundedStateField();
}

class _RoundedStateField extends State<RoundedStateField> {
  IconData? get icon => Icons.person;
  RegExp _legalState = RegExp(r'^[A-Za-z\s]*$');
  bool isLegal = false;

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
            return 'Please enter your state';
          }
          isLegal = onlyLettersAndSpaces(value);
          if (isLegal == false){
            return 'Please enter only letter';
          }
          if (value.length > 50) {
            return 'Your state cannot more than 50 characters!';
          }
          return null;
        },
        keyboardType: TextInputType.text,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "State",
          hintText: "State",
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  bool onlyLettersAndSpaces(String str) {
    return _legalState.hasMatch(str);
  }
}