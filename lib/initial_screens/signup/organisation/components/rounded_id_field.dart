import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedIdField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const RoundedIdField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedIdField> createState() => _RoundedIdField();
}

class _RoundedIdField extends State<RoundedIdField> {
  IconData? get icon => Icons.person;

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
            return 'Please enter your ID Number';
          }
          if (value.length > 20) {
            return 'Your organisation ID cannot more than 20 characters!';
          }
          return null;
        },
        keyboardType: TextInputType.text,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Organisation ID",
          hintText: "Organisation ID",
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }
}