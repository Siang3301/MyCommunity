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
      height: size.height * 0.10,
      padding: const EdgeInsets.fromLTRB(30,2,30,2),
      child: TextFormField(
        obscureText: !_passwordVisible,
        validator: (val) {
          if (val == null || val.isEmpty) {
            return 'Please enter your password';
          } else if (val.length < 8) {
            return 'Password must be at least 8 characters long.';
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
          border: const OutlineInputBorder(),
          labelText: "Password",
          labelStyle: const TextStyle(color: Color(0xFF979797), fontFamily: "SourceSansPro")
        ),
      ),
    );
  }
}

