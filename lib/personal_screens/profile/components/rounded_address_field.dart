import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:string_validator/string_validator.dart';

class RoundedAddressField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String initialValue;

  const RoundedAddressField({
    Key? key,
    required this.onChanged,
    required this.initialValue
  }) : super(key: key);

  @override
  State<RoundedAddressField> createState() => _RoundedNameField();
}

class _RoundedNameField extends State<RoundedAddressField> {
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
            return 'Please enter your Address';
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
          labelText: "Address",
          hintText: "Home Address",
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }
}