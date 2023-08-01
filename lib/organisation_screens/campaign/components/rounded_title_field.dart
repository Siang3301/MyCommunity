import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedTitleField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String initialValue;

  const RoundedTitleField({
    Key? key,
    required this.onChanged,
    required this.initialValue,
  }) : super(key: key);

  @override
  State<RoundedTitleField> createState() => _RoundedTitleField();
}

class _RoundedTitleField extends State<RoundedTitleField> {

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height*0.12,
      padding: const EdgeInsets.only(left: 10,right: 10),
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your campaign title';
          } else if (value.length > 100) {
            return 'Title must be within 80 characters';
          }
          return null;
        },
        keyboardType: TextInputType.text,
        initialValue: widget.initialValue,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        maxLines: 1,
        decoration: const InputDecoration(
          enabledBorder:  OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border:  OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Title*",
          hintText: "Campaign title",
          hintMaxLines: 1,
          errorMaxLines: 1,
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

