import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/Components/square_button.dart';
import 'package:lea_connect/Components/square_text_field.dart';
import 'package:lea_connect/Components/tooltip_text.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Screens/auth/Signup/cubit/signup_cubit.dart';
import 'package:lea_connect/Utilities/validator.dart';
import 'package:provider/provider.dart';

class SignUpForm extends StatefulWidget {
  final SignupInitial signupInitial;

  SignUpForm(this.signupInitial);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  SignupInitial get signupInitial => widget.signupInitial;

  final _formKey = GlobalKey<FormState>();
  late SignupCubit signupCubit;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _pwController = TextEditingController();
  TextEditingController _pwConfirmController = TextEditingController();

  bool _btnEnabled = false;
  bool _obscureText = true;
  switchObscure() => setState(() {
    _obscureText = !_obscureText;
  });
  bool _confirmObscureText = true;
  switchComfirmObscure() => setState(() {
    _confirmObscureText = !_confirmObscureText;
  });

  @override
  void initState() {
    signupCubit = context.read<SignupCubit>();
    _emailController.text = signupInitial.email;
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _pwController.dispose();
    _pwConfirmController.dispose();
    super.dispose();
  }

  Widget _buildEmailField(size) {
    final translations = AppLocalizations.of(context);

    return SquareTextField(
        child: TextFormField(
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
            validator: validatorFor(emailValidator, translations),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: squareInputDecoration(translations.account.email, Icons.mail_outline)));
  }

  Widget _buildPwField(size) {
    final translations = AppLocalizations.of(context);

    return SquareTextField(
        child: TextFormField(
            obscureText: _obscureText,
            controller: _pwController,
            validator: validatorFor(passwordValidator, translations),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: squareInputDecorationPw(translations.account.password,
                Icons.lock_outline, _obscureText, switchObscure)));
  }

  Widget _buildPwConfirmField(size) {
    final translations = AppLocalizations.of(context);

    return SquareTextField(
        child: TextFormField(
            obscureText: _confirmObscureText,
            controller: _pwConfirmController,
            validator: (value) {
              return passwordConfirmValidator(value, _pwController.text, translations);
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: squareInputDecorationPw(
                translations.signup.confirmPassword,
                Icons.lock_outline,
                _confirmObscureText,
                switchComfirmObscure)));
  }

  Widget _buildSignUpBtn() {
    final translations = AppLocalizations.of(context);

    return SquareButton(
      text: translations.signup.submit,
      onPress: () => {
        if (_btnEnabled)
          signupCubit.emit(
            SignupAdditional(
                email: _emailController.text,
                password: _pwConfirmController.text
            )
          )
      },
      color: _btnEnabled ? kAccent : Colors.grey,
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
      onChanged: () =>
          setState(() => _btnEnabled = _formKey.currentState!.validate()),
      child: Column(
        children: <Widget>[
          _buildEmailField(size),
          ToolTipText(
              translations.signup.tooltipEmail),
          _buildPwField(size),
          ToolTipText(
              translations.signup.tooltipPassword),
          _buildPwConfirmField(size),
          SizedBox(height: 20.0),
          if (signupInitial.errorMessage != null)
            Text(
              translateErrorMessage(context, signupInitial.errorMessage!),
              style: TextStyle(color: Colors.red),
            ),
          SizedBox(height: 10.0),
          _buildSignUpBtn(),
          SizedBox(height: 10.0)
        ]
      )
    ));
  }
}
