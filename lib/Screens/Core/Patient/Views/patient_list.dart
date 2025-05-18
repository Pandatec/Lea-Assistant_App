import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lea_connect/Components/patient/slidable_patient_card.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/Data/Models/User.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Screens/Core/Patient/Views/patient_form.dart';
import 'package:lea_connect/Screens/Core/Patient/Views/patient_pair.dart';
import 'package:lea_connect/Screens/Core/cubit/nav_core_cubit.dart';
import 'package:lea_connect/l10n/localizations.dart';

class PatientList extends StatefulWidget {
  final UserSession session;
  final List<Patient> patients;
  final NavCoreCubit core;

  PatientList(this.session, {Key? key, required this.patients, required this.core}) :
    super(key: key);

  @override
  _PatientListState createState() => _PatientListState();
}

class _PatientListState extends State<PatientList> {
  UserSession get session => widget.session;
  List<Patient> get patients => widget.patients;
  NavCoreCubit get core => widget.core;

  bool saveChoice = false;

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);

    selectPatient(Patient patient) {
      if (saveChoice)
        core.savePatient(patient).then((value) => core.emit(NavCoreLoadedPatient(session.user, patient)));
      else {
        authStorage.deletePatientId().then((v) =>
          core.emit(NavCoreLoadedPatient(session.user, patient))
        );
      }
    }

    togglePatientEdit(Patient patient) async {
      Patient? res = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PatientForm(session, patient: patient, patientId: patient.id)
      ));
      if (res != null)
        core.updatePatientsList(res);
    }

    togglePatientPair() async {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PatientPair(session)
      ));
      var usrc = await core.fetchUser();
      if (usrc == null)
        return;
      core
        .ensureNoInvalidPatients(User.fromJson(usrc), context)
        .then((patient) => patient != null ? selectPatient(patient) : null);
    }

    toggleVirtualPatientPair() async {
      final isCreate = session.user.virtual_patients_ids.length == 0;
      CoolAlert.show(
        context: context,
        type: isCreate ? CoolAlertType.info : CoolAlertType.confirm,
        title: isCreate ? translations.patient.title_create : translations.are_you_sure,
        text: isCreate ? translations.patient.create : translations.patient.delete,
        confirmBtnText: translations.yes,
        cancelBtnText: translations.no,
        confirmBtnColor: isCreate ? Colors.green : Theme.of(context).colorScheme.error,
        onConfirmBtnTap: () async {
          Navigator.of(context, rootNavigator: true).pop();
          if (isCreate) {
            await session.createVirtualPatient();
            var usrc = await core.fetchUser();
            if (usrc == null)
              return;
            core
              .ensureNoInvalidPatients(User.fromJson(usrc), context)
              .then((patient) => patient != null ? selectPatient(patient) : null);
          } else {
            await session.deleteVirtualPatient();
            await authStorage.deletePatientId();
            core.loadUser(null);
          }
        }
      );
    }

    Widget _buildSpeedDial() {
      return SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.remove,
        buttonSize: 60,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        children: [
          SpeedDialChild(
            onTap: () => toggleVirtualPatientPair(),
            child: Icon(Icons.smart_toy_sharp),
            backgroundColor: session.user.virtual_patients_ids.length == 0 ?
              Theme.of(context).colorScheme.primary :
              Theme.of(context).colorScheme.error
          ),
          SpeedDialChild(
            onTap: () => togglePatientPair(),
            child: Icon(Icons.dialpad),
            backgroundColor: Theme.of(context).colorScheme.primary
          ),
          /*SpeedDialChild(
              onTap: () => {},
              child: Icon(Icons.bluetooth),
              backgroundColor: Theme.of(context).backgroundColor),*/
        ],
      );
    }

    Widget _buildList() {
      return ListView.separated(
          itemBuilder: (context, index) {
            return SlidablePatientCard(
                patient: patients[index],
                onEdit: (context) {
                  togglePatientEdit(patients[index]);
                },
                onDelete: (context) {},
                onTap: () {
                  selectPatient(patients[index]);
                });
          },
          separatorBuilder: (BuildContext context, int index) => const Divider(
                thickness: 1.5,
                color: Color.fromARGB(68, 158, 158, 158),
                indent: 15.0,
                endIndent: 15.0,
              ),
          itemCount: patients.length);
    }

    Widget _buildSaveBtn() {
      return Row(children: [
        Checkbox(
            value: saveChoice,
            onChanged: (value) => setState(() {
                  saveChoice = !saveChoice;
                })),
        Text(translations.patientList.optionSave)
      ]);
    }

    return Scaffold(
        floatingActionButton: _buildSpeedDial(),
        appBar: AppBar(
          title: Text(
            translations.patientList.title,
            textAlign: TextAlign.center,
          ),
          backgroundColor: kPrimaryColor,
          actions: [IconButton(icon: Icon(Icons.help_outline, color: kAccent,), onPressed: () => {
            CoolAlert.show(
              context: context,
              type: CoolAlertType.info,
              barrierDismissible: true,
              title: translations.helper.title,
              confirmBtnText: translations.helper.confirmbtn,
              text: translations.helper.patient_txt,
              onConfirmBtnTap: () async{
                Navigator.of(context, rootNavigator: true).pop();
                CoolAlert.show(
                  context: context,
                  type: CoolAlertType.info,
                  title: translations.helper.title,
                  text: translations.helper.connect_txt,
                );
              },
              ),
          })],
        ),
        body: patients.isEmpty
            ? Center(
                child: Text(translations.empty),
              )
            : Column(
                children: [Expanded(child: _buildList()), _buildSaveBtn()],
              ));
  }
}
