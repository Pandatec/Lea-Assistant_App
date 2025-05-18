import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Screens/auth/Signup/cubit/signup_cubit.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Screens/auth/Signup/Screens/signup_form.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatelessWidget {
  final SignupInitial signupInitial;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  SignupScreen(this.signupInitial);

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    Size size = MediaQuery.of(context).size;
    Widget _buildTitle() {
      return Text(translations.signup.createAccount,
          textAlign: TextAlign.center,
          style: GoogleFonts.openSans(
              textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
    }

    return Scaffold(
      key: scaffoldKey,
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
      body: Stack(
        children: <Widget>[
          Container(
            height: size.height,
            width: size.width,
            decoration: BoxDecoration(color: kSoftBackGround),
            child: Column(
              children: <Widget>[
                _buildTitle(),
                SizedBox(height: 25.0),
                SignUpForm(signupInitial)
              ]
            )
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
                          translations.signup.alreadyMember,
                          style: TextStyle(fontSize: 17),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Provider.of<WelcomeCubit>(context, listen: false)
                                  .emit(SignIn()),
                          child: Text(
                            translations.signup.connect,
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
    );
  }
}
