import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedPostalField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const RoundedPostalField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedPostalField> createState() => _RoundedPostalField();
}

class _RoundedPostalField extends State<RoundedPostalField> {
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
            return 'Please enter your postal';
          }
          isNum = isNumeric(value);
          if (isNum == false){
            return 'Please enter only numeric';
          }
          if (value.length != 5){
            return 'Postal code must be exactly 5 digits!';
          }
          return null;
        },
        keyboardType: TextInputType.text,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Postal Code",
          hintText: "93250",
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