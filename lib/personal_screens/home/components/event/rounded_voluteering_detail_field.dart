import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedDetailField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  
  const RoundedDetailField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedDetailField> createState() => _RoundedDetailField();
}

class _RoundedDetailField extends State<RoundedDetailField> {

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height*0.20,
      padding: const EdgeInsets.only(left: 10,right: 10),
      child: TextFormField(
        validator: (value) {
          if (value!.length > 800) {
            return 'Volunteering detail must be within 800 characters';
          }
          return null;
        },
        keyboardType: TextInputType.text,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        maxLines: 4,
        decoration: const InputDecoration(
          enabledBorder:  OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border:  OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Volunteering details",
          hintText: "Describe the assistance you looking for",
          errorMaxLines: 1,
          hintMaxLines: 4,
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

