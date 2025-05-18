import 'package:flutter/material.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/cubit/nav_core_cubit.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:provider/src/provider.dart';

class SettingEvent extends StatelessWidget {
  final PatientSession session;

  const SettingEvent(this.session, {Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    final NavCoreCubit coreCubit = context.read<NavCoreCubit>();
    final user = session.user;

    String getSubtitle(bool value) {
      if (value)
        return translations.enabled;
      else
        return translations.disabled;
    }

    Widget _buildEvents() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Text(
              translations.settings.events,
              style: TextStyle(color: Colors.grey)
            ),
          ),
          Card(
            child: ListTile(
              onTap: () async {
                Patient save = session.patient;
                coreCubit.emit(NavCoreLoading());
                var nv = !user.settings.notifSafeZoneTracking;
                var r = await session.patchSettingsNotifSafeZoneTracking(nv);
                eitherThen(context, r)((v) {
                  coreCubit.updateSettings(save);
                });
              },
              title: Text(
                translations.settings.safe_zone_tracking,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(getSubtitle(user.settings.notifSafeZoneTracking)),
              leading: Icon(
                Icons.category,
                size: 40,
              ),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () async {
                Patient save = session.patient;
                coreCubit.emit(NavCoreLoading());
                var nv = !user.settings.notifOfflinePatient;
                var r = await session.patchSettingsNotifOfflinePatient(nv);
                eitherThen(context, r)((v) {
                  coreCubit.updateSettings(save);
                });
              },
              title: Text(
                translations.settings.offline_patient,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(getSubtitle(user.settings.notifOfflinePatient)),
              leading: Icon(
                Icons.wifi_off,
                size: 40,
              ),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () async {
                Patient save = session.patient;
                coreCubit.emit(NavCoreLoading());
                var nv = !user.settings.notifNewLogin;
                var r = await session.patchSettingsNotifNewLogin(nv);
                eitherThen(context, r)((v) {
                  coreCubit.updateSettings(save);
                });
              },
              title: Text(
                translations.settings.new_login,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(getSubtitle(user.settings.notifNewLogin)),
              leading: Icon(
                Icons.login,
                size: 40,
              ),
            ),
          ),
          Card(
            child: ListTile(
              onTap: () async {
                Patient save = session.patient;
                coreCubit.emit(NavCoreLoading());
                var nv = !user.settings.notifSettingModified;
                var r = await session.patchSettingsNotifSettingModified(nv);
                eitherThen(context, r)((v) {
                  coreCubit.updateSettings(save);
                });
              },
              title: Text(
                translations.settings.setting_modified,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(getSubtitle(user.settings.notifSettingModified)),
              leading: Icon(
                Icons.settings,
                size: 40,
              ),
            ),
          )
        ],
      );
    }

    return Container(
      child: _buildEvents(),
    );
  }
}
