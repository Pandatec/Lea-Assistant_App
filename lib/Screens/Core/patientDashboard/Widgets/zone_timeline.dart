import 'dart:ui' as ui;
import 'package:flutter/src/painting/text_style.dart' as flutter;

import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/Widgets/usage_chart.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/patient_dashboard.dart';
import 'package:lea_connect/l10n/localizations.dart';

class ZoneTimeline extends StatefulWidget {
  final Map<String, List<AbstractEvent>> data;
  final Timeframe timeframe;
  final DateTime now;

  ZoneTimeline(this.data, this.timeframe) :
    this.now = DateTime.now();

  @override
  _ZoneTimelineState createState() {
    return _ZoneTimelineState();
  }
}

class _ZoneTimelineState extends State<ZoneTimeline> {
  Map<String, List<AbstractEvent>> get data => widget.data;
  Timeframe get timeframe => widget.timeframe;
  DateTime get now => widget.now;

  _Cam cam = _Cam(0.5, 1);
  double? baseScale;
  double? basePan;
  double? basePanAbs;
  Timeframe? lastTimeframe;
  Offset? lastTapPosition;

  _ZoneTimelineState();

  @override
  Widget build(BuildContext context) {
    if (timeframe != lastTimeframe)
      cam = _Cam(0.5, 1);
    lastTimeframe = timeframe;
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      child: CustomPaint(
        painter: _ZoneTimelinePainter(context, data, timeframe, now, cam, lastTapPosition),
        child: Container(),
      ),
      onScaleStart: (s) {
        baseScale = cam.extent;
        basePan = cam.center;
        basePanAbs = s.focalPoint.dx;
      },
      onScaleUpdate: (s) {
        setState(() {
          final ns = baseScale! / s.horizontalScale;
          final pd = s.localFocalPoint.dx - basePanAbs!;
          cam = _Cam(basePan! - pd / size.width * ns, ns);
          lastTapPosition = null;
        });
      },
      onScaleEnd: (s) {
        baseScale = null;
        basePan = null;
      },
      onTapUp: (t) {
        setState(() {
          lastTapPosition = Offset(t.localPosition.dx, t.localPosition.dy);
        });
      },
    );
  }
}

class _Cam {
  // All zero-normalized
  double center;
  double extent;

  _Cam(this.center, this.extent) {
    if (right() - left() > 1.0) {
      this.center = .5;
      this.extent = 1.0;
    }
    if (left() < 0.0)
      this.center -= left();
    if (right() > 1.0)
      this.center -= right() - 1.0;
  }

  double left() {
    return center - extent * 0.5;
  }

  double right() {
    return center + extent * 0.5;
  }
}

class _ZoneTimelinePainter extends CustomPainter {
  final BuildContext context;
  final Map<String, List<AbstractEvent>> data;
  final Timeframe timeframe;
  final DateTime now;
  final _Cam cam;
  final Offset? tap;

  final Duration dur;
  late final DateTime start;

  _ZoneTimelinePainter(this.context, this.data, this.timeframe, this.now, this.cam, this.tap) :
    dur = timeframeToDuration[timeframe]!
  {
    start = now.subtract(dur);
  }

  // Project point in time to camera space (zero-normalized)
  double project(DateTime p) {
    // World coordinates (dur as space vector)
    final w = p.difference(start).inSeconds / dur.inSeconds;
    // Camera space
    return (w - cam.left()) / (cam.right() - cam.left());
  }

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    /*Offset startingPoint = Offset(0, size.height / 2);
    Offset endingPoint = Offset(size.width, size.height / 2);

    canvas.drawLine(startingPoint, endingPoint, paint);*/

    final h = 1.0 / data.entries.length * size.height;
    var i = 0;
    final pals = StyleFactory.style.getOrderedPalettes(data.entries.length);
    for (final l in data.entries) {
      final c = pals[i].makeShades(1)[0];
      var code = 0xFF000000 + (c.r << 16) + (c.g << 8) + c.b;
      paint = Paint()
        ..color = ui.Color(code)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      for (final e in l.value) {
        final left = project(e.date) * size.width;
        final right = project(e.date.add(e.span)) * size.width;
        final r = Rect.fromLTRB(left, h * i, right, h * (i + 1));
        if (tap != null)
          if (r.contains(tap!)) {
            code &= 0x80FFFFFF;
            paint.color = ui.Color(code);
          }
        canvas.drawRect(r, paint);

        if (tap != null)
          if (r.contains(tap!)) {
            final style = flutter.TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold);
            final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
              ui.ParagraphStyle(
                fontSize:   style.fontSize,
                fontFamily: style.fontFamily,
                fontStyle:  style.fontStyle,
                fontWeight: style.fontWeight,
                textAlign: TextAlign.justify,
              )
            )
              ..pushStyle(style.getTextStyle())
              ..addText(localizeDateHourRange(context, e.date, e.date.add(e.span)));
            final ui.Paragraph paragraph = paragraphBuilder.build()
              ..layout(ui.ParagraphConstraints(width: size.width));
            canvas.drawParagraph(paragraph, r.center);
          }
      }

      final style = flutter.TextStyle(color: Colors.black54);
      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize:   style.fontSize,
          fontFamily: style.fontFamily,
          fontStyle:  style.fontStyle,
          fontWeight: style.fontWeight,
          textAlign: TextAlign.justify,
        )
      )
        ..pushStyle(style.getTextStyle())
        ..addText(l.key);
      final ui.Paragraph paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: size.width));
      canvas.drawParagraph(paragraph, Offset(size.width * .02, h * i + size.height * .02));

      i++;
    }
    for (var i = 0; i < data.entries.length - 1; i++) {
      paint = Paint()
        ..color = Colors.black12
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(0, (i + 1) * h), Offset(size.width, (i + 1) * h), paint);
    }
    paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);

    final ticks_div_count = 8;
    for (var i = 0; i < ticks_div_count; i++) {
      final t = start.add(dur * ui.lerpDouble(cam.left(), cam.right(), i / ticks_div_count)!);
      final off = size.width * i / 7;
      canvas.drawLine(Offset(off, size.height * 0.98), Offset(off, size.height), paint);

      final style = flutter.TextStyle(fontSize: 12, color: Colors.black54);
      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize:   style.fontSize,
          fontFamily: style.fontFamily,
          fontStyle:  style.fontStyle,
          fontWeight: style.fontWeight,
          textAlign: TextAlign.justify,
        )
      )
        ..pushStyle(style.getTextStyle())
        ..addText(eventTickLabel(t, dur));
      final ui.Paragraph paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: size.width));
      canvas.drawParagraph(paragraph, Offset(off - paragraph.maxIntrinsicWidth * 0.5, size.height * 0.97 - paragraph.height));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    final old = oldDelegate as _ZoneTimelinePainter;
    return !(data == old.data && cam == old.cam && timeframe == old.timeframe && now == old.now && tap == old.tap);
  }
}