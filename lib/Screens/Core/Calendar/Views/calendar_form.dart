import 'package:cool_alert/cool_alert.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Components/square_button.dart';
import 'package:lea_connect/Components/square_text_field.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Models/CalendarEvent.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/Utilities/validator.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/nav.dart';

abstract class CalendarFormMode {}

class CalendarFormModeNew extends CalendarFormMode {}

class CalendarFormModeEdit extends CalendarFormMode {
  CalendarEvent toEdit;

  CalendarFormModeEdit(this.toEdit);
}


abstract class CalendarFormRes {}

class CalendarFormResIdentity extends CalendarFormRes {
}
final CalendarFormRes calendarFormResIdentity = CalendarFormResIdentity();

class CalendarFormResCreatedEvent extends CalendarFormRes {
  final CalendarEvent newEvent;

  CalendarFormResCreatedEvent(this.newEvent);
}

class CalendarFormResUpdatedEvent extends CalendarFormRes {
  final CalendarEvent updatedEvent;

  CalendarFormResUpdatedEvent(this.updatedEvent);
}

class CalendarFormResDeletedEvent extends CalendarFormRes {
  final CalendarEvent deletedEvent;

  CalendarFormResDeletedEvent(this.deletedEvent);
}


class CalendarForm extends StatefulWidgetRes<CalendarFormRes> {
  final PatientSession session;
  final CalendarFormMode mode;

  CalendarForm(this.session, this.mode, {Key? key}) :
    super(key: key);

  @override
  _CalendarFormState createResponder() {
    return _CalendarFormState(session, mode);
  }
}

truncateToDay(DateTime datetime) {
  return new DateTime(datetime.year, datetime.month, datetime.day);
}

class _CalendarFormState extends StateRes<CalendarForm, CalendarFormRes> {
  final PatientSession session;
  final CalendarFormMode mode;

  _CalendarFormState(this.session, this.mode)
  {
    if (mode is CalendarFormModeEdit) {
      final e = (mode as CalendarFormModeEdit).toEdit;
      _typeValue = e.type;
      _titleController.text = e.data.title;
      _descController.text = e.data.desc;
      _dueDate = e.date;
      final ld = _dueDate;
      _hourController.text = ld.hour.toString();
      _minuteController.text = ld.minute.toString();
      _dueDate = truncateToDay(_dueDate);
    }
  }

  static GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _typeValue = "REMINDER";
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descController = TextEditingController();
  TextEditingController _dueDateController = TextEditingController();
  TextEditingController _hourController = TextEditingController();
  TextEditingController _minuteController = TextEditingController();

  bool _btnEnabled = false;
  bool _onLoading = false;

  DateTime _dueDate = truncateToDay(DateTime.now());

  @override
  void initState() {
    super.initState();
  }

  String _getType() {
    return _typeValue;
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    _dueDateController.text =
        DateFormat(translations.dateFormat).format(_dueDate);
    Size size = MediaQuery.of(context).size;

    Widget _buildType() {
      return DropdownButton<String>(
        value: _typeValue,
        items: <String>['REMINDER', 'EVENT'].map((String value) => 
          DropdownMenuItem<String>(
            value: value,
            child: Text(localizeEventType(context, value))
          )
        ).toList(),
        onChanged: (value) {
          if (value != null)
            setState(() {
              _typeValue = value;
              _btnEnabled = _formKey.currentState!.validate();
            });
        }
      );
    }

    Widget _buildTitle() {
      return Text(mode is CalendarFormModeNew ?
        translations.calendarForm.createEvent :
        translations.calendarForm.updateEvent,
        style: GoogleFonts.openSans(textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
      );
    }

    Widget _buildTitleField() {
      return SquareTextField(
          child: TextFormField(
              validator: validatorFor(NoNullValidator, translations),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.text,
              controller: _titleController,
              decoration: squareInputDecoration(
                  translations.calendarForm.title, Icons.title)));
    }

    Widget _buildDescField() {
      return SquareTextField(
          child: TextFormField(
              validator: validatorFor(NoNullValidator, translations),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.text,
              controller: _descController,
              decoration: squareInputDecoration(
                  translations.calendarForm.desc, Icons.description)));
    }

    Widget _buildDueDateField() {
      final translations = AppLocalizations.of(context);
      return SquareTextField(
          child: TextFormField(
              readOnly: true,
              onTap: () {
                DatePicker.showDatePicker(context,
                    showTitleActions: true,
                    minTime: kFirstDay,
                    maxTime: kLastDay,
                    onConfirm: (date) {
                      setState(() {
                        _dueDate = truncateToDay(date.toLocal());
                        _dueDateController.text =
                            DateFormat(translations.dateFormat).format(_dueDate);
                      });
                    },
                    currentTime: _dueDate,
                    locale:
                        localeToLocaleType(Localizations.localeOf(context)));
              },
              keyboardType: TextInputType.datetime,
              controller: _dueDateController,
              decoration: squareInputDecoration(
                  translations.calendarForm.date, Icons.schedule)));
    }

    Widget _buildHourField() {
      return SquareTextField(
          child: TextFormField(
              validator: validatorFor(numValidator, translations),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.number,
              controller: _hourController,
              decoration: squareInputDecoration(translations.date.hour, Icons.schedule)));
    }

    Widget _buildMinuteField() {
      return SquareTextField(
          child: TextFormField(
              validator: validatorFor(numValidator, translations),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.number,
              controller: _minuteController,
              decoration: squareInputDecoration(translations.date.minute, Icons.schedule)));
    }

    Widget _buildSaveBtn() {
      Future<Either<ErrorDesc, Map<String, dynamic>>> submit() async {
        if (mode is CalendarFormModeEdit)
          return await session.editCalendarEvent(
            (mode as CalendarFormModeEdit).toEdit.id,
            _getType(),
            EventData(_titleController.text, _descController.text),
            _dueDate.add(Duration(
                hours: int.parse(_hourController.text),
                minutes: int.parse(_minuteController.text)
              )
            ),
            ""
          );
        else
          return await session.createCalendarEvent(
            _getType(),
            EventData(_titleController.text, _descController.text),
            _dueDate.add(Duration(
                hours: int.parse(_hourController.text),
                minutes: int.parse(_minuteController.text)
              )
            ),
            ""
          );
      }

      return SquareButton(
        text: mode is CalendarFormModeNew ?
          translations.calendarForm.validateCreate :
          translations.calendarForm.validateUpdate,
        onPress: () async {
          if (_btnEnabled) {
            setState(() {
              _onLoading = true;
            });
            final r = await submit();
            setState(() {
              _onLoading = false;
            });
            eitherThen(context, r)((v) {
              final ev = CalendarEvent.fromJson(v['event']);
              respond(mode is CalendarFormModeNew ?
                CalendarFormResCreatedEvent(ev) :
                CalendarFormResUpdatedEvent(ev)
              );
            });
          }
        },
        color: _btnEnabled ? kAccent : Colors.grey,
        textColor: Colors.white,
        width: 0.9,
      );
    }

    Widget _buildDeleteBtn() {
      if (!(mode is CalendarFormModeEdit))
        throw Exception("Must be in edit mode to delete");

      final e = (mode as CalendarFormModeEdit).toEdit;
      return SquareButton(
        text: translations.calendarForm.validateDelete,
        onPress: () async {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.confirm,
            title: translations.are_you_sure,
            text: translations.calendarForm.confirmDelete,
            confirmBtnText: translations.yes,
            cancelBtnText: translations.no,
            confirmBtnColor: Theme.of(context).colorScheme.error,
            onConfirmBtnTap: () async {
              setState(() {
                _onLoading = true;
              });
              final r = await session.deleteCalendarEvent(e.id);
              setState(() {
                _onLoading = false;
              });
              eitherThen(context, r)((v) {
                // Pop the "Are you sure?" alert
                Navigator.of(context, rootNavigator: true).pop();
                // Response from form
                respond(CalendarFormResDeletedEvent(e));
              });
            }
          );
        },
        color: Colors.redAccent,
        textColor: Colors.white,
        width: 0.9,
      );
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: kSoftBackGround,
          foregroundColor: Colors.black,
          elevation: 0.0,
          leading: IconButton(
            icon: Icon(
              CupertinoIcons.arrow_left,
              color: Colors.black54,
              size: 30,
            ),
            onPressed: () => respond(CalendarFormResIdentity())
          ),
        ),
        body: _onLoading
            ? LoadingScreen()
            : Form(
                key: _formKey,
                onChanged: () => setState(
                    () => _btnEnabled = _formKey.currentState!.validate()),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Container(
                    width: size.width,
                    decoration: BoxDecoration(color: kSoftBackGround),
                    child: Column(
                      children: <Widget>[
                        _buildTitle(),
                        SizedBox(height: 20.0),
                        _buildType(),
                        _buildTitleField(),
                        _buildDescField(),
                        _buildDueDateField(),
                        _buildHourField(),
                        _buildMinuteField(),
                        _buildSaveBtn()
                      ] + (mode is CalendarFormModeNew ? [] : [
                        SizedBox(height: 20.0),
                        _buildDeleteBtn()
                      ])
                    ),
                  ),
                )
              )
            );
  }
}
