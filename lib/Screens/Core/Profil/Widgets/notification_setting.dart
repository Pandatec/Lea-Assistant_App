import 'package:flutter/material.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/cubit/nav_core_cubit.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:provider/src/provider.dart';

class SettingNotif extends StatelessWidget {
  final PatientSession session;

  SettingNotif(this.session, {Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    final NavCoreCubit coreCubit = context.read<NavCoreCubit>();
    final user = session.user;

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
                Patient save = session.patient;
                coreCubit.emit(NavCoreLoading());
                var nv = !user.settings.dnd;
                var r = await session.patchSettingsDnd(nv);
                eitherThen(context, r)((v) {
                  coreCubit.updateSettings(save);
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

    return Container(
      child: _buildNotifications(),
    );
  }
}
