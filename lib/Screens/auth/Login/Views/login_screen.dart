import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Screens/auth/Login/Views/login_form.dart';
import 'package:lea_connect/Screens/auth/Login/cubit/login_cubit.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  final LoginInitial loginInitial;

  LoginScreen(this.loginInitial);

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    Size size = MediaQuery.of(context).size;
    Widget _buildTitle() {
      return Text(translations.signin.title,
          style: GoogleFonts.openSans(
              textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: kSoftBackGround,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.arrow_left,
            color: Colors.black54,
            size: 30,
          ),
          onPressed: () => context.read<WelcomeCubit>().emit(WelcomeInitial()),
        ),
      ),
      body: Container(
        width: size.width,
        height: size.height,
        child: Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(color: kSoftBackGround),
              child: Column(
                children: <Widget>[
                  _buildTitle(),
                  SizedBox(height: 25.0),
                  LoginForm(loginInitial),
                ],
              ),
            ),
            Container(
                width: size.width,
                height: size.height,
                child: Align(
                  child: Padding(
                      padding: EdgeInsets.only(bottom: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            translations.signin.newMember,
                            style: TextStyle(fontSize: 17),
                          ),
                          GestureDetector(
                            onTap: () =>
                                context.read<WelcomeCubit>().emit(SignUp()),
                            child: Text(
                              translations.signin.createAccount,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: kAccent,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      )),
                  alignment: Alignment.bottomCenter,
                ))
          ],
        ),
      ),
    );
  }
}
