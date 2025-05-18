import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Components/custom_background.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/Bar.dart';
import 'package:lea_connect/Screens/Core/Profil/Widgets/notification_setting.dart';
import 'package:lea_connect/Screens/Core/Profil/Widgets/event_setting.dart';
import 'package:lea_connect/Screens/Core/cubit/nav_core_cubit.dart';
import 'package:lea_connect/l10n/localizations.dart';

class ProfilScreen extends StatefulWidget {
  final PatientSession session;

  ProfilScreen(this.session, {Key? key}) :
    super(key: key);

  @override
  _ProfilScreenState createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  PatientSession get session => widget.session;
  late NavCoreCubit core;

  @override
  void initState() {
    super.initState();
    core = context.read<NavCoreCubit>();
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    Size size = MediaQuery.of(context).size;

    logout() {
      CoolAlert.show(
        context: context,
        type: CoolAlertType.confirm,
        title: translations.are_you_sure,
        text: translations.nav.logoutWarning,
        confirmBtnText: translations.yes,
        cancelBtnText: translations.no,
        confirmBtnColor: Colors.green,
        onConfirmBtnTap: () {
          Navigator.of(context, rootNavigator: true).pop();
          core.authenticateCubit.logout();
        }
      );
    }

    switchPatient() {
      CoolAlert.show(
        context: context,
        type: CoolAlertType.confirm,
        title: translations.are_you_sure,
        text: translations.profile.switchPatientWarning,
        confirmBtnText: translations.yes,
        cancelBtnText: translations.no,
        confirmBtnColor: Colors.green,
        onConfirmBtnTap: () async {
          Navigator.of(context, rootNavigator: true).pop();
          await authStorage.deletePatientId();
          core.loadUser(null);
        }
      );
    }

    Widget _buildProfile() {
      return Container(
        child: Column(
          children: [
            ClipOval(
                child: Image.network(
              "https://picsum.photos/200",
              fit: BoxFit.cover,
              width: 80,
              height: 80,
            )),
            SizedBox(
              height: 5,
            ),
            Text(
              '${session.user.firstName} ${session.user.lastName}',
              style: GoogleFonts.openSans(
                  textStyle: TextStyle(color: Colors.white, fontSize: 25)),
            ),
            Text(
              '${session.user.email}',
              style: GoogleFonts.openSans(
                  textStyle: TextStyle(color: Colors.white, fontSize: 15)),
            )
          ],
        ),
      );
    }

    Widget _buildMid(Size size) {
      return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20.0),
                  topRight: const Radius.circular(20.0))),
          child: Container(
              transform: Matrix4.translationValues(0.0, -25.0, 0.0),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GestureDetector(
                    onTap: switchPatient,
                    child: Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset:
                                  Offset(0, 3), // changes position of shadow
                            ),
                          ]),
                      child: Icon(
                        Icons.swap_horizontal_circle,
                        size: 30,
                        color: kAccent,
                      ),
                    )),
                SizedBox(
                  width: 40,
                ),
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(90.0))),
                  child: Hero(
                    tag: 'logo',
                    child: ClipOval(
                        child: Image.asset(
                      "assets/logos/primary_no_text.png",
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                    )),
                  ),
                ),
                SizedBox(
                  width: 40,
                ),
                GestureDetector(
                    onTap: logout,
                    child: Container(
                      width: 60,
                      height: 60,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20.0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 7,
                              offset:
                                  Offset(0, 3), // changes position of shadow
                            ),
                          ]),
                      child: Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                    ))
              ])));
    }

    Widget _buildContent(Size size) {
      return Expanded(
          child: Container(
              width: size.width,
              transform: Matrix4.translationValues(0.0, -1.0, 0.0),
              child: SingleChildScrollView(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /*SettingLang(session),
                  SizedBox(
                    height: 15,
                  ),*/
                  SettingNotif(session),
                  SizedBox(
                    height: 15,
                  ),
                  SettingEvent(session),
                  SizedBox(
                    height: 15,
                  ),
                  /*Card(
                    child: ListTile(
                      onTap: () => {print("redirect to leassistance")},
                      title: Text(
                        translations.profile.contactSupport,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      leading: Icon(
                        Icons.help_outline,
                        size: 40,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),*/
                  Card(
                    child: ListTile(
                      onTap: () async {
                        CoolAlert.show(
                          context: context,
                          type: CoolAlertType.confirm,
                          title: translations.are_you_sure,
                          text: translations.profile.confirmDeleteAccount,
                          confirmBtnText: translations.yes,
                          cancelBtnText: translations.no,
                          confirmBtnColor: Theme.of(context).colorScheme.error,
                          onConfirmBtnTap: () async {
                            Navigator.of(context, rootNavigator: true).pop();
                            await session.deleteUser(true);
                            core.authenticateCubit.logout();
                          }
                        );
                      },
                      title: Text(
                        translations.profile.deleteAccount,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromRGBO(255, 96, 96, 1.0)),
                      ),
                      leading: Icon(
                        Icons.delete_forever,
                        size: 40,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                  ),
                ],
              )),
              decoration: BoxDecoration(
                color: Colors.white,
              )));
    }

    return Scaffold(
      appBar: Bar(session, Icon(Icons.person)),
      body: CustomBackground(
          child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            _buildProfile(),
            SizedBox(height: 40.0),
            _buildMid(size),
            _buildContent(size)
          ],
        ),
      )),
    );
  }
}
