import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/Utilities/age_calculator.dart';
import 'package:lea_connect/l10n/localizations.dart';

class PatientCard extends StatelessWidget {
  final rng = new Random();
  final Patient patient;

  PatientCard({required this.patient});
  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: Card(
        elevation: 5.0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.black, width: 100),
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: ListTile(
            minVerticalPadding: 14,
            leading: Container(
              margin: EdgeInsets.only(left: 6, top: 5),
              decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Color.fromARGB(127, 158, 158, 158)))),
              child: Padding(
                  padding: const EdgeInsets.only(right: 18.0),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/logos/primary_no_text.png",
                      color: Colors.white.withOpacity(0.75), colorBlendMode: BlendMode.modulate,
                      fit: BoxFit.cover,
                      width: 36,
                      height: 36,
                    ),
                  )),
            ),
            title: Container(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                patient.nickName,
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
              )
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(left: 12, top: 6),
              child: Text(
                  "${calculateAge(DateTime.parse(patient.birthdate))} ${translations.years}"),
            ),
            trailing: Padding(
              child: const Icon(Icons.keyboard_arrow_right, size: 30.0),
              padding: const EdgeInsets.only(top: 7.0),
            )),
      ),
    );
  }
}
