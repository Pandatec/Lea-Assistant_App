import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Data/Models/CalendarEvent.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:table_calendar/table_calendar.dart';

part 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final PatientSession session;
  List<CalendarEvent> _events = [];

  CalendarCubit(this.session) :
    super(CalendarMonthlyState());

  List<CalendarEvent> fetchEventByDate(DateTime day) {
    List<CalendarEvent> res = [];
    _events.forEach((event) {
      if (isSameDay(day, event.date))
        res.add(event);
    });
    return res;
  }

  List<CalendarEvent> fetchUpcoming() {
    List<CalendarEvent> res = [];
    final now = DateTime.now();
    for (final e in _events)
      if (now.compareTo(e.date) < 0)
        res.add(e);
    res.sort((a, b) => a.date.compareTo(b.date));
    return res;
  }

  Map<DateTime, List<CalendarEvent>> fetchUpcomingByDay() {
    Map<DateTime, List<CalendarEvent>> res = {};
    for (final e in fetchUpcoming()) {
      final d = e.date;
      final k = DateTime(d.year, d.month, d.day);
      List<CalendarEvent>? l = res[k];
      if (l == null) {
        l = [];
        res[k] = l;
      }
      l.add(e);
    }
    return res;
  }

  Future<void> loadCalendarEventMonth(DateTime now) async {
    _events = [];
    final res = await session.getCalendarEvents(date_begin: now.subtract(Duration(days: 40)), date_end: now.add(Duration(days: 40)));
    eitherThen(null, res)((v) {
      fillEventList(v['events']);
    });
  }

  Future<void> loadCalendarEventPage(int page) async {
    if (page == 0)
      _events = [];
    final res = await session.getCalendarEvents(page: page);
    eitherThen(null, res)((v) {
      fillEventList(v['events']);
    });
  }

  fillEventList(List json) {
    json.forEach((e) => {
      _events.add(CalendarEvent.fromJson(e))
    });
    switchToLastView();
  }

  void newEvent(Map<String, dynamic> event) {
    final d = event['data'];
    final t = d['type'];
    if (t == 'deleted')
      _events = _events.where((e) => e.id != d['id']).toList();
    else {
      final ce = CalendarEvent.fromJson(d['event']);
      _events = _events.where((e) => e.id != ce.id).toList();
      _events.add(ce);
      _events.sort((a, b) => a.date.compareTo(b.date));
    }
  }

  CalendarState _lastView = CalendarMonthlyState();

  void switchToList() {
    _lastView = CalendarListState();
    emit(_lastView);
  }
  void switchToCalendar() {
    _lastView = CalendarMonthlyState();
    emit(_lastView);
  }
  void switchToLastView() {
    emit(_lastView);
  }
}
