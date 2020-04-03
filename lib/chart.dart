import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class Chart extends StatelessWidget {
  final List<charts.Series> data;

  Chart(this.data);

  @override
  Widget build(BuildContext context) {
    return new charts.TimeSeriesChart(data,
        animate: false,
        primaryMeasureAxis: charts.NumericAxisSpec(
          tickProviderSpec:
              charts.BasicNumericTickProviderSpec(zeroBound: false),
          renderSpec: charts.NoneRenderSpec(),
        ),
        domainAxis: new charts.DateTimeAxisSpec(
            renderSpec: new charts.NoneRenderSpec()));
  }
}

List<charts.Series<dynamic, DateTime>> getChart(List<SensorValue> data) {
  return [
    charts.Series<SensorValue, DateTime>(
      id: 'Values',
      colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
      domainFn: (SensorValue values, _) => values.time,
      measureFn: (SensorValue values, _) => values.value,
      data: data,
    )
  ];
}

/// Sample linear data type.
class SensorValue {
  final DateTime time;
  final double value;

  SensorValue(this.time, this.value);
}
