import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/Screens/Core/Patient/Views/patient_card.dart';
import 'package:lea_connect/l10n/localizations.dart';

class SlidablePatientCard extends StatelessWidget {
  final Patient patient;
  final void Function(BuildContext)? onEdit;
  final void Function(BuildContext)? onDelete;
  final void Function()? onTap;

  SlidablePatientCard({
    Key? key,
    required this.patient,
    required this.onEdit,
    required this.onDelete,
    required this.onTap
  }) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    return Slidable(
      key: const ValueKey(0),
      startActionPane: ActionPane(
        // A motion is a widget used to control how the pane animates.
        motion: const ScrollMotion(),

        // All actions are defined in the children parameter.
        children: [
          // A SlidableAction can have an icon and/or a label.
          SlidableAction(
            onPressed: onDelete,
            backgroundColor: kSlidableColorBackground,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: translations.patientList.optionDelete,
          ),
        ],
      ),
      endActionPane: ActionPane(
        // A motion is a widget used to control how the pane animates.
        motion: const ScrollMotion(),

        // All actions are defined in the children parameter.
        children: [
          // A SlidableAction can have an icon and/or a label.
          SlidableAction(
            onPressed: onEdit,
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: translations.patientList.optionEdit,
          ),
        ],
      ),
      child:
          GestureDetector(onTap: onTap, child: PatientCard(patient: patient)),
    );
  }
}
