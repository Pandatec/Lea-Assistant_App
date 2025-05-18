import 'package:flutter/widgets.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'package:lea_connect/l10n/translations.i69n.dart';
import 'package:lea_connect/l10n/translations_fr.i69n.dart';
import 'package:table_calendar/table_calendar.dart';

const _supportedLocales = ['en', 'fr'];

class AppLocalizations {
  final Translations translations;

  const AppLocalizations(this.translations);

  static final _translations = <String, Translations Function()>{
    'en': () => const Translations(),
    'fr': () => const Translations_fr()
  };

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _ExampleLocalizationsDelegate();

  static final List<Locale> supportedLocales =
      _supportedLocales.map((x) => Locale(x)).toList();

  static Future<AppLocalizations> load(Locale locale) =>
      Future.value(AppLocalizations(_translations[locale.languageCode]!()));

  static Translations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!
          .translations;
}

class _ExampleLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _ExampleLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _supportedLocales.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      AppLocalizations.load(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

LocaleType localeToLocaleType(Locale locale)
{
  var code = locale.languageCode;
  if (code == 'fr')
    return LocaleType.fr;
  else if (code == 'en')
    return LocaleType.en;
  else
    throw Exception("Unknown locale '${code}'");
}

final Map<String, String> _enErrs = {
  'MISSING_FIELD': "Missing field",
  'AUTHENTIFICATION_FAILED': "Authentification failed",
  'ALREADY_REGISTERED': "Already registered",
  'INVALID_FIELD': "Invalid field",
  'NO_FIELD': "No field supplied",
  'UNKNOWN_PATIENT': "Unknown patient",
  'NOT_PAIRED': "Patient not paired",
  'UNKNOWN_CALENDAR_EVENT': "Unknown calendar event",
  'UNKNOWN_CODE': "Unknown pairing code",
  'WAITING_FOR_CONFIRMATION': "Waiting for confirmation",
  'NOT_LOGGED_IN': "Not logged in",
  'INTERNAL_ERROR': "Internal error",
  'USER_DOES_NOT_EXIST': "User does not exist",
  'UNKNOWN_MESSAGE': "Uknown message",
  'INVALID_PATIENT': "Invalid patient",
  'NO_PATH': "Unknown interface path",
  'INVALID_DEVICE_ID': "Invalid device ID",
  'PASSWORD_MISMATCH': "Passwords do not match",
  'TOKEN_EXPIRED': "Session expired",
  'PASSWORD_TOO_SHORT': "Password is not long enough"
};
final Map<String, String> _frErrs = {
  'MISSING_FIELD': "Champ manquant",
  'AUTHENTIFICATION_FAILED': "L'authentification a échoué",
  'ALREADY_REGISTERED': "Ce compte existe déjà",
  'INVALID_FIELD': "Champ invalide",
  'NO_FIELD': "Pas de champ renseigné",
  'UNKNOWN_PATIENT': "Patient inconnu",
  'NOT_PAIRED': "Patient non appairé",
  'UNKNOWN_CALENDAR_EVENT': "Rappel inconnu",
  'UNKNOWN_CODE': "Code d'appairage inconnu",
  'WAITING_FOR_CONFIRMATION': "En attente de confirmation",
  'NOT_LOGGED_IN': "Non connecté",
  'INTERNAL_ERROR': "Erreur interne",
  'USER_DOES_NOT_EXIST': "L'utilisateur n'existe pas",
  'UNKNOWN_MESSAGE': "Message inconnu",
  'INVALID_PATIENT': "Patient invalide",
  'NO_PATH': "Chemin d'interface inconnu",
  'INVALID_DEVICE_ID': "Identifiant d'appareil invalide",
  'PASSWORD_MISMATCH': "Les mots de passe ne correspondent pas",
  'TOKEN_EXPIRED': "Session expirée",
  'PASSWORD_TOO_SHORT': "Le mot de passe n'est pas suffisamment long"
};

String _handleTrErr(Map<String, String> locale, String code, String def)
{
  final r = locale[code];
  if (r == null)
    return "${def}: ${code}";
  else
    return r;
}

String translateErrorMessage(BuildContext ctx, String code) {
  final tra = AppLocalizations.of(ctx);
  if (tra.locale == 'fr')
    return _handleTrErr(_frErrs, code, "Erreur inconnue");
  else
    return _handleTrErr(_enErrs, code, "Unknown error");
}

String localizeHour(BuildContext ctx, DateTime time) {
  final t = time;
  final tra = AppLocalizations.of(ctx);
  String pad(int val) => val.toString().padLeft(2, '0');
  if (tra.locale == 'fr')
    return "${pad(t.hour)} h ${pad(t.minute)}";
  else
    return "${t.hour % 13 + (t.hour > 12 ? 1 : 0)}:${pad(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}";
}

String localizeDateHour(BuildContext ctx, DateTime time) {
  final t = time;
  final tra = AppLocalizations.of(ctx);
  if (tra.locale == 'fr')
    return "${localizeHour(ctx, time)} ${t.day}/${t.month}/${t.year}";
  else
    return "${t.month}/${t.day}/${t.year} ${localizeHour(ctx, time)}";
}

String localizeDateHourRange(BuildContext ctx, DateTime begin, DateTime end) {
  final tra = AppLocalizations.of(ctx);
  if (tra.locale == 'fr')
    return "${localizeDateHour(ctx, begin)} à\n${localizeDateHour(ctx, end)}";
  else
    return "${localizeDateHour(ctx, begin)} to\n${localizeDateHour(ctx, end)}";
}

StartingDayOfWeek localizeStartingDayWeek(BuildContext ctx) {
  final tra = AppLocalizations.of(ctx);
  if (tra.locale == 'fr')
    return StartingDayOfWeek.monday;
  else
    return StartingDayOfWeek.sunday;
}

String localizeDateDay(BuildContext ctx, DateTime date) {
  final tra = AppLocalizations.of(ctx);
  return new DateFormat.yMMMMEEEEd(tra.locale).format(date);
}

final Map<String, String> _enEventTypes = {
  'REMINDER': "Reminder",
  'EVENT': "Event",
};
final Map<String, String> _frEventTypes = {
  'REMINDER': "Rappel",
  'EVENT': "Événement",
};

String localizeEventType(BuildContext ctx, String type) {
  final tra = AppLocalizations.of(ctx);
  if (tra.locale == 'fr')
    return _handleTrErr(_frEventTypes, type, "Type inconnu");
  else
    return _handleTrErr(_enEventTypes, type, "Unknown type");
}

final Map<String, String> _enPatientEventType = {
  'unknown': 'Unintelligible',
  'pairing_accepted': 'Pairing granted',
  'pairing_denied': 'Pairing denied',
  'event_created': 'Event',
  'reminder_created': 'Reminder',
  'message_created': 'Message'
};

final Map<String, String> _frPatientEventType = {
  'unknown': 'Non reconnu',
  'pairing_accepted': 'App. accepté',
  'pairing_denied': 'App. refusé',
  'event_created': 'Événement',
  'reminder_created': 'Rappel',
  'message_created': 'Message'
};

String localizePatientEventType(BuildContext ctx, String type) {
  final tra = AppLocalizations.of(ctx);
  if (tra.locale == 'fr')
    return _handleTrErr(_frPatientEventType, type, 'Inconnu');
  else
    return _handleTrErr(_enPatientEventType, type, 'Unknown');
}

final Map<String, String> _enPatientEventSuccess = {
  'success': 'Understood',
  'failure': 'Unintelligible',
};

final Map<String, String> _frPatientEventSuccess = {
  'success': 'Compris',
  'failure': 'Pas compris',
};

String localizePatientEventSuccess(BuildContext ctx, String type) {
  final tra = AppLocalizations.of(ctx);
  if (tra.locale == 'fr')
    return _handleTrErr(_frPatientEventSuccess, type, 'Inconnu');
  else
    return _handleTrErr(_enPatientEventSuccess, type, 'Unknown');
}