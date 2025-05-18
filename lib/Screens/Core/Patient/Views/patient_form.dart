import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Components/square_button.dart';
import 'package:lea_connect/Components/square_text_field.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/Utilities/validator.dart';
import 'package:lea_connect/l10n/localizations.dart';

class PatientForm extends StatefulWidget {
  final UserSession session;
  final Patient? patient;
  final String patientId;

  PatientForm(this.session, {this.patient, required this.patientId});

  @override
  _PatientFormState createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  UserSession get session => widget.session;

  static GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _nickNameController = TextEditingController();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _birthDateController = TextEditingController();

  bool _btnEnabled = false;
  bool _onLoading = false;

  DateTime birthdate = DateTime.now();

  @override
  void initState() {
    if (widget.patient != null) {
      _nickNameController.text = widget.patient!.nickName;
      _firstNameController.text = widget.patient!.firstName;
      _lastNameController.text = widget.patient!.lastName;
      birthdate = DateTime.parse(widget.patient!.birthdate);
    }
    super.initState();
  }

  tryPatchPatient() {
    setState(() {
      _onLoading = true;
    });
    session
      .patchPatient(
        widget.patientId,
        _nickNameController.text,
        _firstNameController.text,
        _lastNameController.text,
        birthdate.toString()
      ).then((value) {
        either(context, value)((v) {
          widget.patient!.nickName = _nickNameController.text;
          widget.patient!.firstName = _firstNameController.text;
          widget.patient!.lastName = _lastNameController.text;
          widget.patient!.birthdate = birthdate.toString();
          Navigator.of(context, rootNavigator: true).pop(widget.patient!);
        }, (e) {
          setState(() {
            _onLoading = false;
          });
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    _birthDateController.text =
        DateFormat(translations.dateFormat).format(birthdate);
    Size size = MediaQuery.of(context).size;

    Widget _buildTitle() {
      return Text(translations.patientForm.editProfile,
          style: GoogleFonts.openSans(
              textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
    }

    Widget _buildNickNameField() {
      return SquareTextField(
          child: TextFormField(
              validator: validatorFor(alphaValidator, translations),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.text,
              controller: _nickNameController,
              decoration: squareInputDecoration(
                  translations.patientForm.id, Icons.person)));
    }

    Widget _buildFirstNameField() {
      return SquareTextField(
          child: TextFormField(
              validator: validatorFor(alphaValidator, translations),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.text,
              controller: _firstNameController,
              decoration:
                  squareInputDecoration(translations.name, Icons.person)));
    }

    Widget _buildLastNameField() {
      return SquareTextField(
          child: TextFormField(
              validator: validatorFor(alphaValidator, translations),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.text,
              controller: _lastNameController,
              decoration:
                  squareInputDecoration(translations.surname, Icons.person)));
    }

    Widget _buildBirthDateField() {
      final translations = AppLocalizations.of(context);
      return SquareTextField(
          child: TextFormField(
              readOnly: true,
              onTap: () {
                DatePicker.showDatePicker(context,
                    showTitleActions: true,
                    minTime: DateTime(1900, 1, 1),
                    maxTime: DateTime.now(), onConfirm: (date) {
                  setState(() {
                    birthdate = date.toLocal();
                    _birthDateController.text =
                        DateFormat(translations.dateFormat).format(birthdate);
                  });
                },
                    currentTime: birthdate,
                    locale:
                        localeToLocaleType(Localizations.localeOf(context)));
              },
              keyboardType: TextInputType.datetime,
              controller: _birthDateController,
              decoration: squareInputDecoration(
                  translations.birthday, Icons.calendar_today)));
    }

    Widget _buildSaveBtn() {
      return SquareButton(
        text: translations.patientForm.validate,
        onPress: () {
          if (_btnEnabled)
            tryPatchPatient();
        },
        color: _btnEnabled ? kAccent : Colors.grey,
        textColor: Colors.white,
        width: 0.9,
      );
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: kSoftBackGround,
          foregroundColor: Colors.black,
          elevation: 0.0,
        ),
        body: _onLoading
            ? LoadingScreen()
            : Form(
                key: _formKey,
                onChanged: () => setState(
                    () => _btnEnabled = _formKey.currentState!.validate()),
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(color: kSoftBackGround),
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        _buildTitle(),
                        SizedBox(height: 20.0),
                        _buildNickNameField(),
                        _buildFirstNameField(),
                        _buildLastNameField(),
                        _buildBirthDateField(),
                        _buildSaveBtn(),
                      ],
                    ),
                  ),
                )));
  }
}
