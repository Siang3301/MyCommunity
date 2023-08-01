import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedMessageField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  
  const RoundedMessageField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedMessageField> createState() => _RoundedMessageField();
}

class _RoundedMessageField extends State<RoundedMessageField> {

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height*0.20,
      padding: const EdgeInsets.only(left: 10,right: 10),
      child: TextFormField(
        validator: (value) {
          if (value!.length > 200) {
            return 'Volunteering detail must be within 200 characters';
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
          labelText: "Message Customization",
          hintText: "Describe the assistance you looking for... This is the message that the user will see when they received the notification.",
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

