import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedOrgNameField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const RoundedOrgNameField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedOrgNameField> createState() => _RoundedOrgNameField();
}

class _RoundedOrgNameField extends State<RoundedOrgNameField> {
  IconData? get icon => Icons.person;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.10,
      padding: const EdgeInsets.fromLTRB(30,2,30,2),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
      ),
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your Organisation Name';
          }
          if (value.length > 60) {
            return 'Your organisation name cannot more than 60 characters!';
          }
          return null;
        },
        keyboardType: TextInputType.text,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Organisation Name",
          hintText: "Organisation Full Name",
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }
}