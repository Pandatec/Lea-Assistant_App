import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Components/custom_background.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Models/CalendarEvent.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/Bar.dart';
import 'package:lea_connect/Screens/Core/Calendar/Views/calendar_event.dart';
import 'package:lea_connect/Screens/Core/Calendar/Views/calendar_form.dart';
import 'package:lea_connect/Screens/Core/Calendar/cubit/calendar_cubit.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/nav.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarMonthly extends StatefulWidget {
  final PatientSession session;

  CalendarMonthly(this.session, {Key? key}) :
    super(key: key);

  @override
  _CalendarMonthlyState createState() => _CalendarMonthlyState(session);
}

class _CalendarMonthlyState extends State<CalendarMonthly> {
  final PatientSession session;

  _CalendarMonthlyState(this.session);

  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = truncateToDay(DateTime.now());
  late DateTime _selectedDay;
  late WsSubscription _ceventSub;

  @override
  void initState() {
    super.initState();

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(context.read<CalendarCubit>().fetchEventByDate(_selectedDay));
    context.read<CalendarCubit>().loadCalendarEventMonth(_focusedDay).then((value) {
      update();
    });
    wsRepository.enable(session.patient.id, PatientEventClass.CalendarEvent);
    _ceventSub = wsRepository.listen(WsSubscriptionKind.CalendarEvent, (event) {
      context.read<CalendarCubit>().newEvent(event);
      update();
    });
  }

  @override
  void dispose() {
    super.dispose();

    _selectedEvents.dispose();
    _ceventSub.cancel();
    wsRepository.disable(PatientEventClass.CalendarEvent);
  }

  void update() {
    setState(() {
      _selectedEvents.value = context.read<CalendarCubit>().fetchEventByDate(_selectedDay);
    });
  }

  static DateTime reinterpDayUtc(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  static DateTime reinterpDayLocal(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = reinterpDayLocal(selectedDay);
    _focusedDay = reinterpDayLocal(focusedDay);

    update();
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);

    return Scaffold(
      appBar: Bar(session, Icon(Icons.calendar_today), extraActions: [
        IconButton(
          icon: Icon(Icons.list_outlined, color: kAccent,),
          onPressed: () {
            context.read<CalendarCubit>().switchToList();
          }
        )
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        foregroundColor: kSecondaryLightColor,
        child: Icon(Icons.add),
        onPressed: () async {
          await pushNav(context, (ctx) => CalendarForm(session, CalendarFormModeNew()), calendarFormResIdentity);
        }
      ),
      body: CustomBackgroundLinear(
        child: Column(
          children: [
            Card(
              borderOnForeground: true,
              elevation: 5.0,
              margin: EdgeInsets.all(8.0),
              child: TableCalendar<CalendarEvent>(
                locale: translations.locale,
                firstDay: reinterpDayUtc(kFirstDay),
                lastDay: reinterpDayUtc(kLastDay),
                focusedDay: reinterpDayUtc(_focusedDay),
                selectedDayPredicate: (day) => isSameDay(reinterpDayUtc(_selectedDay), reinterpDayUtc(day)),
                calendarFormat: _calendarFormat,
                availableCalendarFormats: {
                  CalendarFormat.month: translations.date.week,
                  CalendarFormat.week: translations.date.month
                },
                eventLoader: (DateTime day) => context.read<CalendarCubit>().fetchEventByDate(reinterpDayLocal(day)),
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: kAccent,
                    shape: BoxShape.circle
                  ),
                  selectedDecoration: BoxDecoration(
                    color: kAccent,
                    shape: BoxShape.circle
                  ),
                  // Use `CalendarStyle` to customize the UI
                  markerDecoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(30)),
                ),
                headerStyle: HeaderStyle(
                    
                    decoration: BoxDecoration(color: kPrimaryColor, border: Border(bottom: BorderSide(color: kSecondaryLightColor))),
                    headerMargin: EdgeInsets.only(bottom: 8.0),
                    titleTextStyle: TextStyle(color: kSecondaryLightColor),
                    formatButtonDecoration: BoxDecoration(
                        border: Border.all(color: kSecondaryLightColor),
                        borderRadius: BorderRadius.circular(10.0)),
                    formatButtonTextStyle: TextStyle(color: kSecondaryLightColor),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      color: kSecondaryLightColor,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      color: kSecondaryLightColor,
                    )),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = reinterpDayLocal(focusedDay);
                  context.read<CalendarCubit>().loadCalendarEventMonth(_focusedDay).then((value) {
                    update();
                  });
                },
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ValueListenableBuilder<List<CalendarEvent>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) => CalendarEventCard(session, value[index])
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
