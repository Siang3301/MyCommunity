import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedRadiusField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const RoundedRadiusField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedRadiusField> createState() => _RoundedRadiusField();
}

class _RoundedRadiusField extends State<RoundedRadiusField> {
  bool isNum = false;
  RegExp _numeric = RegExp(r'^-?[0-9]+$');

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.11,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
      ),
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the radius';
          }
          isNum = isNumeric(value);
          if (isNum == false){
            return 'Please enter only numeric';
          }
        },
        keyboardType: TextInputType.number,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Advertisement radius*",
          hintText: "Radius of advertisement (in meters)",
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
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