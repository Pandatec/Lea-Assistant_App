import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Data/Models/CalendarEvent.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/l10n/localizations.dart';

class WidgetCalendarMediumList extends StatefulWidget {
  final PatientSession session;

  const WidgetCalendarMediumList(this.session, {Key? key}) :
    super(key: key);

  @override
  _WidgetCalendarMediumListState createState() => _WidgetCalendarMediumListState();
}

class _WidgetCalendarMediumListState extends State<WidgetCalendarMediumList> {
  PatientSession get session => widget.session;

  bool is_loaded = false;
  List<CalendarEvent> _events = [];
  late WsSubscription _ceventSub;

  loadCalendarEvent() {
    final now = DateTime.now();
    session.getCalendarEvents(date_begin: now, date_end: now.add(Duration(days: 7))).then((res) {
      eitherThen(context, res)((v) {
        setState(() {
          fillEventList(v['events']);
          is_loaded = true;
        });
      });
    });
  }

  void sortEvents() {
    _events.sort((a, b) {
      return a.date.compareTo(b.date);
    });
  }

  void fillEventList(List json) {
    final now = DateTime.now();
    json.forEach((e) {
      final ce = CalendarEvent.fromJson(e);
      if (now.compareTo(ce.date) < 0)
        _events.add(ce);
    });
    sortEvents();
  }

  @override
  void initState() {
    super.initState();
    loadCalendarEvent();

    wsRepository.enable(session.patient.id, PatientEventClass.CalendarEvent);
    _ceventSub = wsRepository.listen(WsSubscriptionKind.CalendarEvent, (event) {
      setState(() {
        final d = event['data'];
        final t = d['type'];
        if (t == 'deleted')
          _events = _events.where((e) => e.id != d['id']).toList();
        else {
          final ce = CalendarEvent.fromJson(d['event']);
          _events = _events.where((e) => e.id != ce.id).toList();
          final now = DateTime.now();
          if (ce.date.isAfter(now) && ce.date.isBefore(now.add(Duration(days: 7))))
            _events.add(ce);
          sortEvents();
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    _ceventSub.cancel();
    wsRepository.disable(PatientEventClass.CalendarEvent);
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);

    return is_loaded ? Container(
      child: _events.length > 0 ? Card(
        child: ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: min(3, _events.length),
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                minVerticalPadding: 10,
                title: Text(
                  _events[index].data.title,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: Text(_events[index].data.desc),
                ),
              );
            })
        ) :
        Container(
          padding: EdgeInsets.only(top: 32.0),
          child: Text(translations.home.events.empty,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)
          )
        )
      ) :
    LoadingScreen();
  }
}
