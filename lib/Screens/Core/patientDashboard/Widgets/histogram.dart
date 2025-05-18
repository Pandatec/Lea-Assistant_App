/// Bar chart example
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:lea_connect/Constants/style.dart';

class Histogram extends StatelessWidget {
  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  /// Creates a [BarChart] with sample data and no transition.
  factory Histogram.withSampleData() {
    return new Histogram(
      seriesList: _createSampleData(),
      animate: true,
    );
  }

  factory Histogram.withData(List<HistogramEntry> entries) {
    return Histogram(
      seriesList:  [
        charts.Series<HistogramEntry, String>(
          id: 'Sales',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (HistogramEntry sales, _) => sales.name,
          measureFn: (HistogramEntry sales, _) => sales.count,
          data: entries,
          fillColorFn: (HistogramEntry sales, _) => charts.MaterialPalette.purple.shadeDefault,
        )
      ],
      animate: true,
    );
  }

  Histogram({Key? key, required this.seriesList, required this.animate}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return new charts.BarChart(
      seriesList,
      animate: animate,
    );
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<HistogramEntry, String>> _createSampleData() {
    final data = [
      HistogramEntry('Memo', 5),
      HistogramEntry('GPS', 25),
      HistogramEntry('Calendar', 100),
      HistogramEntry('Message', 75),
    ];

    return [
      new charts.Series<HistogramEntry, String>(
        id: 'Sales',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (HistogramEntry sales, _) => sales.name,
        measureFn: (HistogramEntry sales, _) => sales.count,
        data: data,
        fillColorFn: (HistogramEntry sales, _) => charts.MaterialPalette.purple.shadeDefault,
      )
    ];
  }
}

/// Sample ordinal data type.
class HistogramEntry {
  final String name;
  final num count;
  final Color? color = kAccent;

  HistogramEntry(this.name, this.count);
}
