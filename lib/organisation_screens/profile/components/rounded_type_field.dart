import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedCategoryField extends StatefulWidget {
  final Function(String)? onCategorySelected;
  final String initialValue;

  const RoundedCategoryField({
    Key? key,
    required this.onCategorySelected,
    required this.initialValue,
  }) : super(key: key);

  @override
  State<RoundedCategoryField> createState() => _RoundedCategoryField();
}

class _RoundedCategoryField extends State<RoundedCategoryField> {
  String? valueChoose = null;

  List<DropdownMenuItem<String>> get dropdownItems{
    List<DropdownMenuItem<String>> menuItems = const [
      DropdownMenuItem(child: Text("Non-Profit Organisation"),value: "Non-Profit Organisation"),
      DropdownMenuItem(child: Text("For-Profit companies"),value: "For-Profit companies"),
      DropdownMenuItem(child: Text("Government agencies"),value: "Government agencies"),
      DropdownMenuItem(child: Text("Religious organizations"),value: "Religious organizations"),
      DropdownMenuItem(child: Text("Civic organizations"),value: "Civic organizations"),
      DropdownMenuItem(child: Text("Community-based organizations"),value: "Community-based organizations"),
    ];
    return menuItems;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height*0.08,
      padding: const EdgeInsets.fromLTRB(10,2,10,2),
      child : DropdownButtonHideUnderline(
        child : DropdownButtonFormField(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFA5A2A2), width: 1.0),
                borderRadius: BorderRadius.circular(20),
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFA5A2A2), width: 1.0),
                borderRadius: BorderRadius.circular(20),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) => value == null ? "Select a category" : null,
            hint: const Text("Category ", style: TextStyle(color: softTextColor, fontFamily: "SourceSansPro")),
            dropdownColor: Colors.grey,
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 30,
            isExpanded: true,
            style: const TextStyle(
              overflow: TextOverflow.visible,
              color: darkTextColor,
              fontSize: 14,
            ),
            value: widget.initialValue,
            onChanged: (String? newValue) {
              setState(() {
                valueChoose = newValue!;
              });
              if (widget.onCategorySelected != null) {
                widget.onCategorySelected!(valueChoose!);
              }
            },
            items: dropdownItems),
      ),
    );
  }
}