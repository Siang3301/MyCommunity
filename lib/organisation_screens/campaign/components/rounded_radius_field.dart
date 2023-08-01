import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedRadiusField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String initialValue;

  const RoundedRadiusField({
    Key? key,
    required this.onChanged,
    required this.initialValue
  }) : super(key: key);

  @override
  State<RoundedRadiusField> createState() => _RoundedRadiusField();
}

class _RoundedRadiusField extends State<RoundedRadiusField> {
  bool isNum = false;
  RegExp _numeric = RegExp(r'^[0-9]+([.][0-9]+)?$');

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
          isNum = isNumericWithDot(value);
          if (isNum == true){
            return null;
          }else{
            return 'Please enter only numeric';
          }
        },
        keyboardType: TextInputType.number,
        initialValue: widget.initialValue,
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

  bool isNumericWithDot(String str) {
    if (str == null || str.isEmpty) {
      return false;
    }

    final regex = RegExp(r'^[0-9]+([.][0-9]+)?$');
    return regex.hasMatch(str);
  }
}