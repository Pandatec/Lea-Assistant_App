import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:lea_connect/Constants/url.dart';
import 'package:lea_connect/Data/Models/User.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/App.dart';
import 'package:lea_connect/Screens/auth/cubit/auth_cubit.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() {
  print("Host at ${host.fullHost}, running ${version}");
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState()..applyDefaultSettings();

  static _AppState of(BuildContext context) =>
      context.findAncestorStateOfType<_AppState>()!;
}

final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

class _AppState extends State<App> {
  Locale? _locale;
  bool _isDND = false;

  applyDefaultSettings() {
    setLocale('default');
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _isDND = false;
  }

  applyDefaultSettingsState() {
    setState(() {
      applyDefaultSettings();
    });
  }

  applySettings(Settings settings) {
    setState(() {
      setLocale(settings.lang);
      _isDND = settings.dnd;
    });
  }

  setLocale(String locale) {
    locale = 'fr';
    if (locale == 'default')
      _locale = Locale.fromSubtags(languageCode: Intl.getCurrentLocale());
    else
      _locale = Locale(locale, '');
  }

  setLocaleState(String locale) {
    setState(() {
      setLocale(locale);
    });
  }

  bool isDND() {
    return _isDND;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.purple
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _locale,
        home: BlocProvider<AuthenticateCubit>(
          create: (BuildContext context) => AuthenticateCubit()..resume(),
          child: SafeArea(
            child: AppView(),
          ),
        ),
        navigatorKey: navigatorKey);
  }
}