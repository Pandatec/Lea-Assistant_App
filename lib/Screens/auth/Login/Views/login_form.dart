import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Components/square_button.dart';
import 'package:lea_connect/Components/square_text_field.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Screens/auth/Login/cubit/login_cubit.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';
import 'package:lea_connect/Utilities/validator.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:provider/provider.dart';

class LoginForm extends StatefulWidget {
  final LoginInitial loginInitial;

  LoginForm(this.loginInitial);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  LoginInitial get loginInitial => widget.loginInitial;

  final _formKey = GlobalKey<FormState>();
  late LoginCubit loginCubit;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _pwController = TextEditingController();

  bool _rememberMe = false;
  bool _btnEnabled = false;
  bool _obscureText = true;
  switchObscure() => setState(() {
    _obscureText = !_obscureText;
  });

  @override
  void initState() {
    loginCubit = context.read<LoginCubit>();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
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

  Widget _buildPwField(size) {
    final translations = AppLocalizations.of(context);
    return SquareTextField(
        child: TextFormField(
      obscureText: _obscureText,
      controller: _pwController,
      decoration: squareInputDecorationPw(
          translations.account.password, Icons.lock_outline, _obscureText, switchObscure),
      validator: validatorFor(passwordValidator, translations),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    ));
  }

  Widget _buildLoginBtn() {
    final translations = AppLocalizations.of(context);
    return SquareButton(
      text: translations.signin.connect,
      onPress: () => {
        if (_btnEnabled)
          loginCubit.trySignIn(_emailController.text, _pwController.text, _rememberMe)
      },
      color: _btnEnabled ? kAccent : Colors.grey,
      textColor: Colors.white,
      width: 0.9,
    );
  }

  Widget _buildStaySigned() {
    final translations = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.only(left: 7.0),
      child: Row(
        children: <Widget>[
          Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              }),
          Text(
            translations.signin.stayConnected,
            style: GoogleFonts.openSans(
                textStyle: TextStyle(
                    fontWeight: FontWeight.bold, color: kAccent)),
          )
        ],
      ),
    );
  }

  Widget _buildForgotPW() {
    final translations = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.read<WelcomeCubit>().emit(ForgotPassword()),
      child: Text(translations.signin.forgotPassword,
        style: GoogleFonts.openSans(
            textStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kAccent))));
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
        child: Form(
      key: _formKey,
      onChanged: () =>
          setState(() => _btnEnabled = _formKey.currentState!.validate()),
      child: Column(
        children: <Widget>[
          _buildEmailField(size),
          _buildPwField(size),
          _buildStaySigned(),
          SizedBox(height: 20.0),
          if (loginInitial.errorMessage != null)
            Text(
              translateErrorMessage(context, loginInitial.errorMessage!),
              style: TextStyle(color: Colors.red),
            ),
          SizedBox(height: 10.0),
          _buildLoginBtn(),
          SizedBox(height: 10.0),
          _buildForgotPW()
        ]
      )
    ));
  }
}
