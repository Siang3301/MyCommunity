import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycommunity/services/constants.dart';

class RoundedDateField extends StatefulWidget {
  final Function(DateTimeRange)? onDateRangeSelected;
  
  const RoundedDateField({
    Key? key,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  State<RoundedDateField> createState() => _RoundedDateField();
}

class _RoundedDateField extends State<RoundedDateField> {
  DateTime now = DateTime.now();
  DateTimeRange? dateRange;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      padding: const EdgeInsets.only(left: 10,right: 10),
      child:Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: size.width*0.35,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    side: const BorderSide(width: 1.0, color: darkTextColor)
                ),
                onPressed: (){
                  pickDateRange(context);
                },
                child: FittedBox(
                  child: Text(
                    getFrom(),
                    style: const TextStyle(fontSize: 14, color: mainTextColor),
                  )
                )
            )
          ),
          const Icon(Icons.arrow_forward, color: softTextColor),
          SizedBox(
              width: size.width*0.35,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      side: BorderSide(width: 1.0, color: darkTextColor)
                  ),
                  onPressed: (){
                    pickDateRange(context);
                  },
                  child: FittedBox(
                    child: Text(
                        getUntil(),
                        style: TextStyle(fontSize: 14, color: mainTextColor)),
                  )
              )
          )
        ],
      ),
    );
  }

  //set date
  Future pickDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(Duration(hours: 24 * 3)),
    );
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDateRange: dateRange,
    );

    if (newDateRange == null) return;

    setState(() => dateRange = newDateRange);

    if (widget.onDateRangeSelected != null) {
      widget.onDateRangeSelected!(newDateRange);
    }

  }

  String getFrom() {
    if (dateRange == null) {
      return 'Select date';
    } else {
      return DateFormat('MM/dd/yyyy').format(dateRange!.start);
    }
  }

  String getUntil() {
    if (dateRange == null) {
      return 'Select date';
    } else {
      return DateFormat('MM/dd/yyyy').format(dateRange!.end);
    }
  }
}


