import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedFeedbackField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const RoundedFeedbackField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedFeedbackField> createState() => _RoundedFeedbackField();
}

class _RoundedFeedbackField extends State<RoundedFeedbackField> {
  IconData? get icon => Icons.person;
  RegExp _legalusername = RegExp(r'^[A-Za-z\s]*$');
  bool isLegal = false;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.30,
      padding: const EdgeInsets.fromLTRB(10,2,10,2),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
      ),
      child: TextFormField(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your feedback';
          }
          return null;
        },
        keyboardType: TextInputType.text,
        onChanged: widget.onChanged,
        maxLines: 7,
        cursorColor: kPrimaryColor,
        decoration: const InputDecoration(
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border: OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Feedback",
          hintText: "Write any feedback to the admin to helps to improve a better user experience in future!",
          hintStyle: TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  bool onlyLettersAndSpaces(String str) {
    return _legalusername.hasMatch(str);
  }

}