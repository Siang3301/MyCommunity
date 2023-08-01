import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PieChartWidget extends StatefulWidget {
  final List<VolunteerData> data;

  PieChartWidget(this.data);

  @override
  _PieChartWidget createState() => _PieChartWidget();
}

class _PieChartWidget extends State<PieChartWidget> {

  @override
  Widget build(BuildContext context) {

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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top:20),
                child:Text(
                  'Number of Volunteers',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(height: 10), // Adjust the spacing as needed
              SfCircularChart(
                series: <CircularSeries>[
                  DoughnutSeries<VolunteerData, String>(
                    dataSource: widget.data,
                    xValueMapper: (VolunteerData volunteer, _) => volunteer.label,
                    yValueMapper: (VolunteerData volunteer, _) => volunteer.value,
                    dataLabelMapper: (VolunteerData volunteer, _) =>
                    '${volunteer.label}: ${volunteer.value}',
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      connectorLineSettings: ConnectorLineSettings(
                        color: Colors.black,
                        length: '10%',
                      ),
                      textStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        overflow: TextOverflow.visible,
                        fontSize: 12,
                      ),
                      labelIntersectAction: LabelIntersectAction.shift,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
    );
  }
}

class VolunteerData {
  final String label;
  final int value;

  VolunteerData(this.label, this.value);
}
