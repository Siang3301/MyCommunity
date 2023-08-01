import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedCategoryField extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const RoundedCategoryField({
    Key? key,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<RoundedCategoryField> createState() => _RoundedCategoryField();
}

class _RoundedCategoryField extends State<RoundedCategoryField> {
  String? valueChoose = null;

  List<DropdownMenuItem<String>> get dropdownItems{
    List<DropdownMenuItem<String>> menuItems = const [
      DropdownMenuItem(child: Text("Aid & Community"),value: "Aid & Community"),
      DropdownMenuItem(child: Text("Animal Welfare"),value: "Animal Welfare"),
      DropdownMenuItem(child: Text("Art & Culture"),value: "Art & Culture"),
      DropdownMenuItem(child: Text("Children & Youth"),value: "Children & Youth"),
      DropdownMenuItem(child: Text("Education & Lectures"),value: "Education & Lectures"),
      DropdownMenuItem(child: Text("Disabilities"),value: "Disabilities"),
      DropdownMenuItem(child: Text("Environment"),value: "Environment"),
      DropdownMenuItem(child: Text("Food & Hunger"),value: "Food & Hunger"),
      DropdownMenuItem(child: Text("Health & Medical"),value: "Health & Medical"),
      DropdownMenuItem(child: Text("Technology"),value: "Technology"),
      DropdownMenuItem(child: FittedBox(fit: BoxFit.cover, child: const Text("Skill-based\nVolunteering")),value: "Skill-based Volunteering"),
    ];
    return menuItems;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
        height: size.height*0.12,
        padding: const EdgeInsets.only(right: 10),
        margin: EdgeInsets.only(bottom: 10),
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
              validator: (value) => value == null ? "Select a category*" : null,
              hint: const Text("Category* ", style: TextStyle(color: softTextColor, fontFamily: "SourceSansPro")),
              dropdownColor: Colors.grey,
              icon: const Icon(Icons.arrow_drop_down),
              iconSize: 30,
              isExpanded: true,
              style: const TextStyle(
                overflow: TextOverflow.visible,
                color: darkTextColor,
                fontSize: 14,
              ),
              value: valueChoose,
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