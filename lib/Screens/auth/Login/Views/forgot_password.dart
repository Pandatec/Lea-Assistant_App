import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Components/square_button.dart';
import 'package:lea_connect/Components/square_text_field.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/Utilities/validator.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:provider/provider.dart';

class ForgotPasswordForm extends StatefulWidget {
  ForgotPasswordForm();

  @override
  _ForgotPasswordFormState createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  TextEditingController _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _btnEnabled = false;
  bool _formSubmitted = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildEmailField(size) {
    final translations = AppLocalizations.of(context);
    return SquareTextField(
        child: TextFormField(
      keyboardType: TextInputType.emailAddress,
      controller: _emailController,
      decoration: squareInputDecoration(translations.account.email, Icons.mail_outline),
      validator: validatorFor(emailValidator, translations),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    ));
  }

  Widget _buildResetBtn() {
    final translations = AppLocalizations.of(context);
    return SquareButton(
      text: translations.forgotPw.submit,
      onPress: () async {
        if (_btnEnabled && !_formSubmitted) {
          setState(() {
            _formSubmitted = true;
            _btnEnabled = false;
          });
          final res = await UserRepository().sendResetMail(_emailController.text);
          eitherThen(context, res)((v) {
            setState(() {
              _emailSent = true;
            });
          });
        }
      },
      color: _btnEnabled ? kPrimaryColor : Colors.grey,
      textColor: Colors.white,
      width: 0.9,
    );
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    Size size = MediaQuery.of(context).size;
    return Container(
      child: Form(
      key: _formKey,
      onChanged: () => setState(() => _btnEnabled = _formKey.currentState!.validate() && !_formSubmitted),
      child: Column(
        children: <Widget>[
          _buildEmailField(size),
          SizedBox(height: 20.0),
          SizedBox(height: 10.0),
          _buildResetBtn(),
        ] + (_emailSent ? <Widget>[
          SizedBox(height: 16.0),
          Text(translations.forgotPw.mail_resent, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
        ] : <Widget>[])
      )
    ));
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen();

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    Size size = MediaQuery.of(context).size;
    Widget _buildTitle() {
      return Text(translations.forgotPw.title,
          textAlign: TextAlign.center,
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
                ForgotPasswordForm()
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
                          translations.forgotPw.accountBack,
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
                                color: kPrimaryColor,
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

