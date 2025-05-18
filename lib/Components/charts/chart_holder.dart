import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/Widgets/histogram.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/Widgets/usage_chart.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/patient_dashboard.dart';

class ChartHolder extends StatefulWidget {
  final String title;
  final String desc;
  final Map<String, List<AbstractEvent>> data;
  final Timeframe timeframe;

  ChartHolder(this.data, this.timeframe, {
    Key? key,
    required this.title,
    required this.desc,
  }) :
    super(key: key);

  @override
  _ChartHolderState createState() {
    return _ChartHolderState();
  }
}

class _ChartHolderState extends State<ChartHolder> {
  String get title => widget.title;
  String get desc => widget.desc;
  Map<String, List<AbstractEvent>> get data => widget.data;
  Timeframe get timeframe => widget.timeframe;

  bool _isStacked = false;

  _ChartHolderState();

  List<HistogramEntry> histogramData() {
    List<HistogramEntry> res = [];
    for (final e in data.entries) {
      num acc = 0;
      for (final ee in e.value)
        acc += ee.count;
      res.add(HistogramEntry(e.key, acc.round()));
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.openSans(
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    )
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12),
                ),
              ]
            ),
            Expanded(child:
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, color: !_isStacked ? kAccent : Colors.black38),
                  Switch(value: _isStacked, onChanged: (v) {
                    setState(() {
                      _isStacked = v;
                    });
                  }),
                  Icon(Icons.ssid_chart, color: _isStacked ? kAccent : Colors.black38)
                ]
              )
            )
          ]),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: size.width * 0.9,
                    height: size.height * 0.3,
                    child: _isStacked ?
                      UsageChart.withData(data, timeframe) :
                      Histogram.withData(histogramData())
                  )
                ]
              )
            ]
          )
        ],
      )
    );
  }
}

class SliderHolder extends StatelessWidget {
  final String title;
  final String desc;
  final Widget child;

  SliderHolder(this.child, {
    Key? key,
    required this.title,
    required this.desc
  }) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(),
            child: Text(
              title,
              style: GoogleFonts.openSans(
                  textStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              )),
              textAlign: TextAlign.left,
            ),
          ),
          Container(
            width: size.width * 0.8,
            child: Text(
              desc,
              style: TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            width: size.width,
            alignment: Alignment.center,
            child: child,
          )
        ]
      )
    );
  }
}
