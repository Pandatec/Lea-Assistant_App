import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Components/custom_background.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/Bar.dart';
import 'package:lea_connect/Screens/Core/Calendar/Views/calendar_event.dart';
import 'package:lea_connect/Screens/Core/Calendar/Views/calendar_form.dart';
import 'package:lea_connect/Screens/Core/Calendar/cubit/calendar_cubit.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/nav.dart';

class CalendarList extends StatefulWidget {
  final PatientSession session;

  CalendarList(this.session, {Key? key}) :
    super(key: key);

  @override
  _CalendarListState createState() => _CalendarListState(session);
}

class _CalendarListState extends State<CalendarList> {
  final PatientSession session;

  int _page = 0;
  bool _isLoading = false;
  ScrollController _scController = ScrollController();
  late WsSubscription _ceventSub;

  _CalendarListState(this.session);

  @override
  void initState() {
    super.initState();

    _isLoading = true;
    context.read<CalendarCubit>().loadCalendarEventPage(_page).then((value) {
      setState(() {
        _page++;
        _isLoading = false;
      });
    });
    wsRepository.enable(session.patient.id, PatientEventClass.CalendarEvent);
    _ceventSub = wsRepository.listen(WsSubscriptionKind.CalendarEvent, (event) {
      setState(() {
        context.read<CalendarCubit>().newEvent(event);
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
    final days = <Widget>[];
    context.read<CalendarCubit>().fetchUpcomingByDay().forEach((d, es) {
      days.add(Column(children: [
        Divider(),
        Text(localizeDateDay(context, d), style: TextStyle(color: kPrimaryColor),),
        Column(children: es.map((e) =>
          CalendarEventCard(session, e)
        ).toList())
      ]));
    });

    return Scaffold(
      appBar: Bar(session, Icon(Icons.calendar_today_outlined, color: kAccent,), extraActions: [
        IconButton(
          icon: Icon(Icons.calendar_month_outlined, color: kAccent,),
          onPressed: () => context.read<CalendarCubit>().switchToCalendar()
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
      body: Stack(
        children: [
          CustomBackground(),
          NotificationListener(
            child: SingleChildScrollView(
              controller: _scController,
              child: Column(children: days + [Divider(), Icon(Icons.pending, color: Colors.black12), SizedBox(height: 40)])
              ),
              onNotification: (t) {
                if (t is ScrollEndNotification && !_isLoading && (_scController.position.pixels == _scController.position.maxScrollExtent)) {
                  _isLoading = true;
                  context.read<CalendarCubit>().loadCalendarEventPage(_page).then((value) {
                    setState(() {
                      _page++;
                      _isLoading = false;
                    });
                  });
                }
                return true;
              }
            ),
        ],
      )
    );
  }
}
