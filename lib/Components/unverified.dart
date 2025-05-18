import 'package:flutter/material.dart';
import 'package:lea_connect/Components/square_button.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Screens/auth/cubit/auth_cubit.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:provider/provider.dart';

class UnverifiedScreen extends StatefulWidget {
  final UserSession session;

  UnverifiedScreen(this.session, {Key? key}) :
    super(key: key);

  @override
  _UnverifiedScreenState createState() {
    return _UnverifiedScreenState(session);
  }
}

class _UnverifiedScreenState extends State<UnverifiedScreen> {
  final UserSession session;
  bool clickedResentMail = false;
  bool resentMail = false;

  late WsSubscription _sub;

  _UnverifiedScreenState(this.session);

  @override
  void initState() {
    super.initState();
    _sub = wsRepository.listen(WsSubscriptionKind.Verified, (event) {
      context.read<AuthenticateCubit>().emit(Authenticated(session.user.email, session.token, session.user));
    });
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);

    return Scaffold(
      floatingActionButton: Container(padding: EdgeInsets.only(top: 16), child: FloatingActionButton(
        child: Icon(Icons.logout),
        onPressed: () async {
          context.read<AuthenticateCubit>().logout();
        }
      )),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(translations.unverified.title, textAlign: TextAlign.center, style: TextStyle(fontSize: 32)),
            SizedBox(height: 16.0),
            Text("${translations.unverified.msg_begin} ${session.user.email} ${translations.unverified.msg_end}", textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
            SizedBox(height: 48.0)
          ] + (clickedResentMail ?
            (resentMail ? <Widget>[
              Text(translations.unverified.mail_resent, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
            ] : <Widget>[]
          ) : <Widget>[
            Text(translations.unverified.no_mail, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8.0),
            SquareButton(
              color: kAccent,
              text: translations.unverified.rensend_mail,
              onPress: () async {
                setState(() {
                  clickedResentMail = true;
                });
                final res = await session.resendVerifInstr();
                eitherThen(context, res)((v) {
                  setState(() {
                    resentMail = true;
                  });
                });
              }
            )
          ])
        )
      )
    );
  }
}
