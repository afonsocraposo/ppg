/// Example of a simple line chart.
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class Chart extends StatelessWidget {
  final List<charts.Series> data;

  Chart(this.data);

  @override
  Widget build(BuildContext context) {
    return new charts.LineChart(data,
        animate: false,
        primaryMeasureAxis: charts.NumericAxisSpec(
          tickProviderSpec:
              charts.BasicNumericTickProviderSpec(zeroBound: false),
          renderSpec: charts.NoneRenderSpec(),
        ),
        domainAxis: new charts.NumericAxisSpec(
            tickProviderSpec:
                charts.BasicNumericTickProviderSpec(zeroBound: false),
            renderSpec: new charts.NoneRenderSpec()));
  }
}

List<charts.Series<dynamic, num>> getChart(List<SensorValue> data) {
  return [
    charts.Series<SensorValue, int>(
      id: 'Values',
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (SensorValue values, _) => values.time,
      measureFn: (SensorValue values, _) => values.value,
      data: data,
    )
  ];
}

/// Sample linear data type.
class SensorValue {
  final int time;
  final double value;

  SensorValue(this.time, this.value);
}
