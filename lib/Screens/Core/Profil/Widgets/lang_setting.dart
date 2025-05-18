import 'package:flutter/material.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/cubit/nav_core_cubit.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/main.dart';
import 'package:provider/src/provider.dart';

class SettingLang extends StatelessWidget {
  final PatientSession session;

  const SettingLang(this.session, {Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    final NavCoreCubit coreCubit = context.read<NavCoreCubit>();
    final user = session.user;
    final translations = AppLocalizations.of(context);

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
        var setValue = (String? value) async {
          if (value == null) return;
          App.of(context).setLocaleState(value);
          Navigator.of(context, rootNavigator: true).pop();
          Patient save = session.patient;
          coreCubit.emit(NavCoreLoading());
          var r = await session.patchSettingsLang(value);
          eitherThen(context, r)((v) {
            coreCubit.updateSettings(save);
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
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: Text(translations.settings.language),
                content: Column(children: <Widget>[
                  genTile(translations.settings.lang.sys_default, 'default'),
                  genTile(translations.settings.lang.en, 'en'),
                  genTile(translations.settings.lang.fr, 'fr')
                ])));
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

    return Container(
      child: _buildLang(),
    );
  }
}
