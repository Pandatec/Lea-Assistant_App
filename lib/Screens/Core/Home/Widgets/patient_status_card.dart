import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/l10n/localizations.dart';

import '../../../../Data/Repository/patient_session.dart';
import '../../Messenger/Views/messenger.dart';

class PatientStatusCard extends StatelessWidget {
  final String title;
  final bool isConnected;
  final double? battery;
  final PatientSession session;
  final String state;

  PatientStatusCard(
      {Key? key,
      required this.session,
      required this.title,
      required this.isConnected,
      required this.state,
      required this.battery})
      : super(key: key);


  Widget _getEmoticon(String state) {
    switch(state) {
      case 'home':
        return Icon(Icons.sentiment_very_satisfied_outlined, size: 40, color: session.patient.stateColor());
      case 'danger':
        return Icon(Icons.sentiment_very_dissatisfied_outlined, size: 40, color: session.patient.stateColor());
      case 'guard':
        return Icon(Icons.sentiment_very_dissatisfied_outlined, size: 40, color: session.patient.stateColor());
      case 'safe':
        return Icon(Icons.sentiment_satisfied_outlined, size: 40, color: session.patient.stateColor());
      case 'unknown':
        return Icon(Icons.sentiment_dissatisfied_outlined, size: 40, color: session.patient.stateColor());
    }
    return Icon(Icons.sentiment_satisfied, size: 40, color: session.patient.stateColor());
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      elevation: 8.0,
      child: ListTile(
          leading: ClipOval(
              child: Image.network(
            "https://picsum.photos/200",
            fit: BoxFit.cover,
            width: 50,
            height: 50,
          )),
          title: Text(
            title,
            style: GoogleFonts.openSans(
                textStyle:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          subtitle: Row(children: [
            isConnected
                ? Transform.rotate(
                    angle: 90 * math.pi / 180,
                    child: Icon(Icons.battery_charging_full,
                        size: 25,
                        color: battery == null
                            ? Colors.grey
                            : Color.lerp(
                                Colors.red[500], Colors.green, battery!)))
                : SizedBox(),
            SizedBox(
              width: 5,
            ),
            Text(battery != null
                ? '${translations.home.battery} ${(battery! * 100.0).toStringAsFixed(2)}%'
                : translations.home.battery_err)
          ]),
          trailing: IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: Duration(seconds: 1),
                    pageBuilder: (_, __, ___) {
                      return Messenger(session, '');
                    }
                  )
                );
            },
            icon: Icon(Icons.message_outlined, color: kAccent,))),
    );
  }
}
