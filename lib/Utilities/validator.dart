import 'package:lea_connect/l10n/translations.i69n.dart';
import 'package:string_validator/string_validator.dart';

String? Function(String?) validatorFor(
    String? Function(String?, Translations) fun, Translations translations) {
  return (String? str) {
    return fun(str, translations);
  };
}

String? emailValidator(String? input, Translations translations) {
  if (input == null || input.isEmpty) return translations.validator.textNeeded;
  String pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = new RegExp(pattern);

  if (!regex.hasMatch(input)) return translations.validator.invalidFormat;
  return null;
}

String? passwordValidator(String? input, Translations translations) {
  if (input == null || input.isEmpty) return translations.validator.textNeeded;
  return null;
}

passwordConfirmValidator(input, src, translations) {
  if (input.isEmpty) return translations.validator.textNeeded;
  if (input != src) return translations.validator.passwordMismatch;
  return null;
}

String? alphaValidator(String? input, Translations translations) {
  if (input == null || input.isEmpty) return translations.validator.textNeeded;
  if (!isAlpha(input)) return translations.validator.invalidChars;
  return null;
}

String? numValidator(String? input, Translations translations) {
  if (input == null || input.isEmpty) return translations.validator.textNeeded;
  if (isAlpha(input)) return translations.validator.invalidChars;
  return null;
}

String? NoNullValidator(String? input, Translations translations) {
  if (input == null || input.isEmpty) return translations.validator.textNeeded;
  return null;
}
