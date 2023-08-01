import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';

class TimePickerWidget extends StatefulWidget {
  final Function(TimeOfDay)? onTimeSelected;

  const TimePickerWidget({Key? key, required this.onTimeSelected}) : super(key:key);

  @override
  _TimePickerWidgetState createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  TimeOfDay? time;

  @override
  void dispose(){
    super.dispose();
    time = null;
  }

  String getText() {
    if (time == null) {
      return 'Select Time';
    } else {
      final hours = time!.hour.toString().padLeft(2, '0');
      final minutes = time!.minute.toString().padLeft(2, '0');

      return '$hours:$minutes';
    }
  }

  @override
  Widget build(BuildContext context) => ButtonHeaderWidget(
    title: 'Time',
    text: getText(),
    onClicked: () => pickTime(context),
  );

  Future pickTime(BuildContext context) async {
    final initialTime = TimeOfDay(hour: 9, minute: 0);
    final newTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (newTime == null) return;

    setState(() {time = newTime;});
    if (widget.onTimeSelected != null) {
      widget.onTimeSelected!(newTime);
    }
  }
}

class ButtonHeaderWidget extends StatelessWidget {
  final String title;
  final String text;
  final VoidCallback onClicked;

  const ButtonHeaderWidget({
    Key? key,
    required this.title,
    required this.text,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.only(left: 10,right: 10),
      width: size.width*0.35,
      child: HeaderWidget(
      title: title,
      child: ButtonWidget(
        text: text,
        onClicked: onClicked,
      ),
    )
    );
  }
}

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;

  const ButtonWidget({
    Key? key,
    required this.text,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ElevatedButton(
    style: ElevatedButton.styleFrom(
        primary: Colors.white,
        side: const BorderSide(width: 1.0, color: darkTextColor)
    ),
    onPressed: onClicked,
    child: FittedBox(
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: mainTextColor),
      ),
    ),
  );
}

class HeaderWidget extends StatelessWidget {
  final String title;
  final Widget child;

  const HeaderWidget({
    Key? key,
    required this.title,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      child,
    ],
  );
}



