import 'package:flutter/material.dart';
import 'package:lea_connect/Data/Models/CalendarEvent.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/Calendar/Views/calendar_form.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/nav.dart';

final _reminderImg = NetworkImage("https://icon-library.com/images/notifications-icon/notifications-icon-8.jpg");
final _eventImg = NetworkImage("https://www.pinclipart.com/picdir/middle/63-634205_events-icon-brain-png-clipart.png");

class CalendarEventCard extends StatelessWidget {
  final PatientSession session;
  final CalendarEvent event;

  CalendarEventCard(this.session, this.event);

  Widget getLeadingFromType(String type) {
    if (type == 'REMINDER')
      return ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.8), BlendMode.dstATop),
        child: CircleAvatar(
          radius: 18,
          backgroundImage: AssetImage('assets/images/notification.png')
        )
      );
    if (type == 'EVENT')
      return ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.7), BlendMode.dstATop),
        child: CircleAvatar(
          radius: 18,
          backgroundImage: AssetImage('assets/images/event.png')
        )
      );
    return Container();
  }

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 10.0, vertical: 5.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.black, width: 100),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: ListTile(
          minVerticalPadding: 10,
          leading: getLeadingFromType(event.type),
          title: Text(
            event.data.title,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(left: 3),
            child: Text(event.data.desc),
          ),
          trailing: Text(localizeHour(ctx, event.date),
            style: TextStyle(
              color: Colors.black54,
              fontSize: 20
            )
          ),
          onTap: () async {
            await pushNav(ctx, (ctx) => CalendarForm(session, CalendarFormModeEdit(event)), calendarFormResIdentity);
          }
        ),
      ),
    );
  }
}