import 'package:flutter/material.dart';
import 'package:mycommunity/services/constants.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DonutChartWidget extends StatelessWidget {
  final List<ChartData> data;

  DonutChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    double engagementPercentage = (data[0].value / data[1].value) * 100;

    return Container(
      padding: const EdgeInsets.all(10),
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
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'Comparison between volunteers needed and volunteers joined',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              'All-time Engagement Percentage',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(height: 10),
          data.first.value == 0 && data.last.value == 0 ?
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 70, bottom: 10),
            child: Text(
              'Lets organize a campaign to start to view the statistic!', textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ):
          Stack(
            alignment: Alignment.center,
            children: [
              SfCircularChart(
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.label,
                    yValueMapper: (ChartData data, _) => data.value,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelMapper: (ChartData data, _) =>
                    '${data.label}: ${data.value}',
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
                  )
                ],
              ),
              Text(
                '${engagementPercentage.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String label;
  final int value;
  final Color color;

  ChartData(this.label, this.value, {required this.color});
}