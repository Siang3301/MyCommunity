import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const SearchField({
    Key? key,
    required this.onChanged
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 15, right: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: searchBorder,
        ),
        boxShadow: [
          BoxShadow(
            offset: Offset(3, 3),
            blurRadius: 10,
            color: Colors.black.withOpacity(0.16),
            spreadRadius: -2,
          )
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: "Search your activity",
          hintStyle: TextStyle(
            fontSize: 13,
            color: softTextColor,
            fontFamily: "Poppins"
          ),
          prefixIcon: Icon(Icons.search, color: kPrimaryColor),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10
          ),
        ),
      ),
    );
  }
}