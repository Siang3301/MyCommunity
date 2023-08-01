import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedLocationLinkField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  
  const RoundedLocationLinkField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedLocationLinkField> createState() => _RoundedLocationLinkField();
}

class _RoundedLocationLinkField extends State<RoundedLocationLinkField> {

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height*0.12,
      padding: const EdgeInsets.only(left: 10,right: 10),
      child: TextFormField(
         validator: (value) {
           if (value!.length > 150) {
             return 'Location link must be within 150 characters';
           }
           return null;
         },
        keyboardType: TextInputType.text,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        maxLines: 1,
        decoration: const InputDecoration(
          enabledBorder:  OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border:  OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Location link",
          hintText: "Link of your shared location.",
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

