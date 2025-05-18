import 'package:flutter/cupertino.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/l10n/translations_fr.i69n.dart';

class Settings {
  final String id;
  final bool darkModeIsDefault;
  final bool darkMode;  // undefined if default
  final String lang;  // might be default
  final bool dnd;

  final bool notifSafeZoneTracking;
  final bool notifOfflinePatient;
  final bool notifNewLogin;
  final bool notifSettingModified;

  Settings(
      {required this.id, required this.darkModeIsDefault, required this.darkMode, required this.lang, required this.dnd,
      required this.notifSafeZoneTracking, required this.notifOfflinePatient, required this.notifNewLogin, required this.notifSettingModified});

  static bool _getDarkMode(dynamic dbValue) {
    if (dbValue is String && dbValue == "default") {  // default
      return false;
    } else if (dbValue is bool) {
      return dbValue;
    } else
      throw Exception("Unknown dark mode value");
  }

  Settings.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        darkModeIsDefault = (json['dark_mode'] is String) && (json['dark_mode'] == "default"),
        darkMode = _getDarkMode(json['dark_mode']),
        lang = json['lang'],
        dnd = json['dnd'],

        notifSafeZoneTracking = json['notif_safe_zone_tracking'],
        notifOfflinePatient = json['notif_offline_patient'],
        notifNewLogin = json['notif_new_login'],
        notifSettingModified = json['notif_setting_modified'];

  // returns value that should actually be used
  bool isDarkMode(BuildContext context) {
    if (darkModeIsDefault)
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    else
      return darkMode;
  }

  bool isLangDefault() {
    return lang == "default";
  }

  String getLang(BuildContext context) {
    if (lang == "default") {
      final translations = AppLocalizations.of(context);
      if (translations is Translations_fr)
        return "fr";
      else  // en is base class
        return "en";
    } else
      return lang;
  }
}

class User {
  final String? id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final bool active;
  List<Patient> patients;
  List<String> virtual_patients_ids;
  Settings settings;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.active,
    required this.patients,
    required this.virtual_patients_ids,
    required this.settings
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var list = json['patients'] as List;
    List<Patient> patientList = list.isNotEmpty ?
      list.map((i) => Patient.fromJson(i)).toList() :
      [];

    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      email: json['email'],
      active: json['active'],
      patients: patientList,
      virtual_patients_ids: (json['virtual_patients_ids'] as List<dynamic>).map((v) => v as String).toList(),
      settings: Settings.fromJson(json['settings'])
    );
  }

  bool isVerified() {
    return active;
  }

  Patient fetchPatient(id) =>
      patients.firstWhere((element) => element.id == id);
}
