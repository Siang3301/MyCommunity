import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedPasswordField extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const RoundedPasswordField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<RoundedPasswordField> createState() => _RoundedPasswordFieldState();
}

class _RoundedPasswordFieldState extends State<RoundedPasswordField> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    void _toggle() {
      setState(() {
        _passwordVisible = !_passwordVisible;
      });
    }
    return Container(
      height: size.height * 0.12,
      padding: const EdgeInsets.fromLTRB(30,2,30,2),
      child: TextFormField(
        obscureText: !_passwordVisible,
        validator: (val) {
          if (val == null || val.isEmpty) {
            return 'Please enter your password';
          } else if (val.length < 8) {
            return 'Password must be at least 8 characters long.';
          } else if (!val.contains(new RegExp(r'[A-Z]'))) {
            return 'Password must contain at least one capital letter.';
          } else if (!val.contains(new RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
            return 'Password must contain at least one special character.';
          }
          return null;
        },
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            icon:Icon(
            _passwordVisible ?
            Icons.visibility
            : Icons.visibility_off,
            color: kPrimaryColor,
          ),
            onPressed: (){_toggle();},
          ),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          border: const OutlineInputBorder(borderSide: BorderSide(color: darkTextColor, width: 1.0)),
          labelText: "Password",
          hintText: "Password",
          hintStyle: const TextStyle(color: softTextColor, fontFamily: "SourceSansPro"),
          labelStyle: const TextStyle(color: darkTextColor, fontFamily: "SourceSansPro"),

          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }
}

