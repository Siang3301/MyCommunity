import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:string_validator/string_validator.dart';

class RoundedVolunteerField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const RoundedVolunteerField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedVolunteerField> createState() => _RoundedVolunteerField();
}

class _RoundedVolunteerField extends State<RoundedVolunteerField> {
  bool isNum = false;
  RegExp _numeric = RegExp(r'^-?[0-9]+$');

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height*0.12,
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
      ),
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Enter volunteers (1-500)';
          }
          isNum = isNumeric(value);
          if (isNum == false){
            return 'Numeric only';
          }
          if (int.parse(value) == 0){
            return 'You cannot put 0 volunteer!';
          }
          if (int.parse(value) > 500){
            return 'You cannot organize an campaign more than 500 people!';
          }
          return null;
        },
        keyboardType: TextInputType.number,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Volunteer*",
          hintText: "Volunteer (1-500)",
          errorMaxLines: 3,
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro", fontSize: 12),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  bool isNumeric(String age) {
    return _numeric.hasMatch(age);
  }
}