import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/cubit/nav_core_cubit.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/main.dart';

class SettingsScreen extends StatelessWidget {
  final PatientSession session;

  SettingsScreen(this.session);

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    final NavCoreCubit coreCubit = context.read<NavCoreCubit>();
    Size size = MediaQuery.of(context).size;
    final user = session.user;

    Widget _buildLang() {
      String getTitle() {
        if (user.settings.lang == 'default')
          return translations.settings.lang.sys_default;
        else
          return translations.settings.lang.overriden;
      }

      String getSubtitle() {
        var l = user.settings.getLang(context);
        if (l == 'en')
          return translations.settings.lang.en;
        else if (l == 'fr')
          return translations.settings.lang.fr;
        else
          throw Exception("Uknown language");
      }

      showOptions() async {
        showDialog(
            context: context,
            builder: (context) {
              var setValue = (String? value) async {
                if (value == null)
                  return;
                Navigator.pop(context);
                App.of(context).setLocaleState(value);
                coreCubit.emit(NavCoreLoading());
                var r = await session.patchSettingsLang(value);
                eitherThen(context, r)((v) {
                  coreCubit.loadUser(context);
                });
              };
              var genTile = (String text, String value) {
                return ListTile(
                    title: Text(text),
                    leading: Radio<String>(
                        value: value,
                        groupValue: user.settings.lang,
                        onChanged: setValue));
              };
              return AlertDialog(
                title: Text(translations.settings.language),
                content: Column(children: <Widget>[
                  genTile(translations.settings.lang.sys_default, 'default'),
                  genTile(translations.settings.lang.en, 'en'),
                  genTile(translations.settings.lang.fr, 'fr')
                ]));
            }
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Text(
              translations.settings.language,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Card(
            child: ListTile(
              onTap: showOptions,
              title: Text(
                getTitle(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(getSubtitle()),
              leading: Icon(
                Icons.translate,
                size: 40,
              ),
            ),
          )
        ],
      );
    }

    Widget _buildNotifications() {
      String getSubtitle() {
        if (user.settings.dnd)
          return translations.enabled;
        else
          return translations.disabled;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Text(
              translations.settings.notifications,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () async {
                coreCubit.emit(NavCoreLoading());
                var nv = !user.settings.dnd;
                var r = await session.patchSettingsDnd(nv);
                eitherThen(context, r)((v) {
                  coreCubit.loadUser(context);
                });
              },
              title: Text(
                translations.settings.dnd,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(getSubtitle()),
              leading: Icon(
                Icons.do_disturb_sharp,
                size: 40,
              ),
            ),
          )
        ],
      );
    }

    /*Widget _buildDarkMode() {
      String getTitle() {
        if (user.settings.darkModeIsDefault)
          return translations.settings.them.sys_default;
        else
          return translations.settings.them.overriden;
      }

      String getSubtitle() {
        if (user.settings.isDarkMode(context))
          return translations.settings.them.dark;
        else
          return translations.settings.them.light;
      }

      showOptions() async {
        var setValue = (String? value) async {
          if (value == null)
            return;
          Navigator.of(context, rootNavigator: true).pop();
          coreCubit.emit(CoreLoading());
          var r = await session.patchSettingsDarkMode(value == 'default' ? value : value == 'dark');
          eitherThen(r)((v) {
            coreCubit.loadUser(context);
          });
        };
        var genTile = (String text, String value) {
          return ListTile(
              title: Text(text),
              leading: Radio<String>(
                value: value,
                groupValue: user.settings.darkModeIsDefault ? 'default' : (user.settings.darkMode ? 'dark' : 'light'),
                onChanged: setValue
              )
            );
        };
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(translations.settings.theme),
            content: Column(
              children: <Widget>[
                genTile(translations.settings.them.sys_default, 'default'),
                genTile(translations.settings.them.light, 'light'),
                genTile(translations.settings.them.dark, 'dark')
              ]
            )
          )
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Text(
              translations.settings.theme,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          Card(
            child: ListTile(
              onTap: showOptions,
              title: Text(
                getTitle(),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(getSubtitle()),
              leading: Icon(
                Icons.dark_mode,
                size: 40,
              ),
            ),
          )
        ],
      );
    }*/

    return Container(
      width: size.width,
      decoration: BoxDecoration(color: kSoftBackGround),
      child: Column(
        children: <Widget>[
          SizedBox(height: 25.0),
          _buildLang(),
          SizedBox(height: 25.0),
          _buildNotifications(),
          //SizedBox(height: 25.0),
          //_buildDarkMode(),
        ]
      )
    );
  }
}
