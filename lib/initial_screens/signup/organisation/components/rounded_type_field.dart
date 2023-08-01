import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedTypeField extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const RoundedTypeField({
    Key? key,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<RoundedTypeField> createState() => _RoundedTypeField();
}

class _RoundedTypeField extends State<RoundedTypeField> {
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(35,2,30,2),
          child : const Text("Organisation Type", style: TextStyle(fontSize: 14, fontFamily: "SourceSansPro", color: darkTextColor)),
        ),
        Container(
          height: size.height*0.12,
          padding: const EdgeInsets.fromLTRB(30,5,30,2),
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
                isExpanded: false,
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
        )
      ],
    );
  }
}