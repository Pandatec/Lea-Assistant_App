import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/patient_dashboard.dart';

String eventTickLabel(DateTime date, Duration dur) {
  if (dur < Duration(days: 3))
    return "${date.hour}h";
  else
    return "${date.day}/${date.month}";
}

class UsageChart extends StatelessWidget {
  final List<charts.Series<dynamic, num>> seriesList;
  final bool animate;
  final DateTime now;
  final charts.NumericTickFormatterSpec tickFormatter;

  UsageChart({Key? key, required this.seriesList, required this.animate, required this.now, required this.tickFormatter}) :
    super(key: key);

  factory UsageChart.withData(Map<String, List<AbstractEvent>> data, Timeframe timeframe) {
    final now = DateTime.now();
    final dur = timeframeToDuration[timeframe]!;
    final gran = timeframeToGranularity[timeframe]!;
    final start = now.subtract(dur);
    final tf = charts.BasicNumericTickFormatterSpec((num? value) {
      final date = start.add(gran * value!);
      return eventTickLabel(date, dur);
    });
    return UsageChart(seriesList: _createSeries(data, timeframe, now), animate: true, now: now, tickFormatter: tf);
  }

  static List<charts.Series<Usage, num>> _createSeries(Map<String, List<AbstractEvent>> data, Timeframe timeframe, DateTime now) {
    List<charts.Series<Usage, num>> res = [];
    final dur = timeframeToDuration[timeframe]!;
    final gran = timeframeToGranularity[timeframe]!;
    final entryCount = dur.inSeconds ~/ gran.inSeconds + 1;
    final start = now.subtract(dur);

    for (final l in data.entries) {
      List<Usage> us = [];
      for (var i = 0; i < entryCount; i++)
        us.add(Usage(i, 0));
      for (final ae in l.value) {
        var i = max(ae.date.difference(start).inSeconds ~/ gran.inSeconds, 0);
        if (ae.span.inSeconds == 0)
          us[i].y += ae.count;
        else {
          var cur = ae.date.difference(start);
          var next = gran * (i + 1);
          var acc = ae.span;
          while (true) {
            final cspan = next - cur;
            if (acc < cspan) {
              if (i < us.length)
                us[i].y += ae.count * acc.inSeconds ~/ ae.span.inSeconds;
              break;
            } else {
              if (i < us.length)
                us[i].y += ae.count * cspan.inSeconds ~/ ae.span.inSeconds;
              acc -= cspan;
            }

            cur = next;
            i++;
            next = gran * (i + 1);;
          }
        }
      }
      res.add(charts.Series<Usage, num>(
        id: l.key,
        domainFn: (Usage sales, _) => sales.x,
        measureFn: (Usage sales, _) => sales.y,
        data: us,
      ));
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(
      seriesList,
      behaviors: [charts.SeriesLegend(desiredMaxColumns: 3)],
      defaultRenderer: new charts.LineRendererConfig(includeArea: true, stacked: false),
      animate: animate,
      primaryMeasureAxis: new charts.NumericAxisSpec(
        tickProviderSpec: new charts.BasicNumericTickProviderSpec(desiredTickCount: 6),
      ),
      domainAxis: charts.NumericAxisSpec(
        tickProviderSpec: charts.BasicNumericTickProviderSpec(desiredTickCount: 7),
        tickFormatterSpec: tickFormatter,
      ),
    );
  }
}

class Usage {
  final num x;
  num y;

  Usage(this.x, this.y);
}