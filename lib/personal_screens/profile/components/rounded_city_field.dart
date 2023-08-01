import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:string_validator/string_validator.dart';

class RoundedCityField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String initialValue;

  const RoundedCityField({
    Key? key,
    required this.onChanged,
    required this.initialValue
  }) : super(key: key);

  @override
  State<RoundedCityField> createState() => _RoundedNameField();
}

class _RoundedNameField extends State<RoundedCityField> {
  IconData? get icon => Icons.person;

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
            return 'Please enter your city';
          } else if (!isAlpha(value)) {
            return 'Only Letters Please';
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
          labelText: "City",
          hintText: "City",
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }
}