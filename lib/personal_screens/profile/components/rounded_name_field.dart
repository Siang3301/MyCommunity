import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:string_validator/string_validator.dart';

class RoundedNameField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String initialValue;

  const RoundedNameField({
    Key? key,
    required this.onChanged,
    required this.initialValue
  }) : super(key: key);

  @override
  State<RoundedNameField> createState() => _RoundedNameField();
}

class _RoundedNameField extends State<RoundedNameField> {
  IconData? get icon => Icons.person;
  RegExp _legalusername = RegExp(r'^[A-Za-z\s]*$');
  bool isLegal = false;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.10,
      padding: const EdgeInsets.fromLTRB(10,2,10,2),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
      ),
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your username';
          }
          isLegal = onlyLettersAndSpaces(value);
          if (isLegal == false){
            return 'Please enter only letter';
          }
          return null;
        },
        keyboardType: TextInputType.text,
        initialValue: widget.initialValue,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Name",
          hintText: "Full Name",
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  bool onlyLettersAndSpaces(String str) {
    return _legalusername.hasMatch(str);
  }

}