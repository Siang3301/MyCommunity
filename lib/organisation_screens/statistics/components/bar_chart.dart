import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class BarChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> usersPromotedList;

  BarChartWidget(this.usersPromotedList);

  @override
  _BarChartWidgetState createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  int currentWeekOffset = 0; // Offset to adjust the current week

  @override
  Widget build(BuildContext context) {
    final List<String> daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate the current week start and end dates based on the current offset
    DateTime now = DateTime.now();
    DateTime currentWeekStart = now.subtract(Duration(days: now.weekday - 1)).add(Duration(days: 7 * currentWeekOffset));
    DateTime currentWeekEnd = currentWeekStart.add(Duration(days: 6));

    // Filter the usersPromotedList based on the current week
    List<Map<String, dynamic>> filteredList = widget.usersPromotedList
        .where((entry) {
      DateTime entryDate = DateTime.parse(entry['date']);
      return entryDate.isAfter(currentWeekStart.subtract(Duration(days: 1))) &&
          entryDate.isBefore(currentWeekEnd.add(Duration(days: 1)));
    })
        .toList();

    // Create a list to store the counts for each day of the week
    final List<int> counts = List<int>.filled(7, 0);

    // Iterate over the filteredList and populate the counts for each day
    for (final entry in filteredList) {
      DateTime date = DateTime.parse(entry['date']);
      int dayOfWeek = date.weekday - 1; // 1-7 to 0-6 index
      counts[dayOfWeek] += entry['count'] as int;
    }

    // Create a list to store the data points for the chart
    final List<DataPoint> dataPoints = List<DataPoint>.generate(
      daysOfWeek.length,
          (index) => DataPoint(daysOfWeek[index], counts[index]),
    );

    return Scaffold(
      backgroundColor: mainBackColor,
      body: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
        color: mainBackColor,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4.0,
            spreadRadius: 1.0,
            offset: Offset(0, 3), // Adjust the offset as needed
          ),
        ],
      ),
      child:Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'Number of Users Promoted Per day',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: mainTextColor,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: mainTextColor),
                  onPressed: () {
                    setState(() {
                      currentWeekOffset--; // Decrease the current week offset
                    });
                  },
                ),
                Text(
                  '${currentWeekStart.day}/${currentWeekStart.month}/${currentWeekStart.year} - ${currentWeekEnd.day}/${currentWeekEnd.month}/${currentWeekEnd.year}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: mainTextColor, fontFamily: 'Poppins'),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: mainTextColor),
                  onPressed: () {
                    setState(() {
                      currentWeekOffset++; // Increase the current week offset
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: mainTextColor,
                ),
                title: AxisTitle(text: 'Day', textStyle: TextStyle(fontFamily: 'Poppins', color: mainTextColor, fontWeight: FontWeight.bold)),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: mainTextColor,
                ),
                title: AxisTitle(
                  text: 'Number of Users',
                  textStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: mainTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                decimalPlaces: 0,
                interval: 1,
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                  final DataPoint dataPoint = data as DataPoint;
                  DateTime date = currentWeekStart.add(Duration(days: pointIndex));
                  String formattedDate = '${date.day}/${date.month}';
                  return Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mainBackColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mainTextColor),
                    ),
                  );
                },
              ),
              series: <ChartSeries>[
                ColumnSeries<DataPoint, String>(
                  dataSource: dataPoints,
                  xValueMapper: (dataPoint, _) => dataPoint.day,
                  yValueMapper: (dataPoint, _) => dataPoint.count,
                ),
              ],
            ),
          ),
        ],
       ),
      )
    );
  }
}

class DataPoint {
  final String day;
  final int count;

  DataPoint(this.day, this.count);
}