import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Components/square_button.dart';
import 'package:lea_connect/Components/square_text_field.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Screens/auth/Signup/cubit/signup_cubit.dart';
import 'package:lea_connect/Utilities/validator.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:provider/provider.dart';

class SignUpAdditionalForm extends StatefulWidget {
  final SignupAdditional signupAdditional;

  SignUpAdditionalForm(this.signupAdditional);

  @override
  _SignUpAdditionalFormState createState() => _SignUpAdditionalFormState();
}

class _SignUpAdditionalFormState extends State<SignUpAdditionalForm> {
  SignupAdditional get signupAdditional => widget.signupAdditional;

  static GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late SignupCubit signupCubit;
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  bool _btnEnabled = false;

  @override
  void initState() {
    signupCubit = context.read<SignupCubit>();
    super.initState();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildFirstNameField(size) {
    final translations = AppLocalizations.of(context);
    return SquareTextField(
        child: TextFormField(
            keyboardType: TextInputType.name,
            controller: _firstNameController,
            validator: validatorFor(alphaValidator, translations),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: squareInputDecoration(translations.name, Icons.person)));
  }

  Widget _buildLastNameField(size) {
    final translations = AppLocalizations.of(context);
    return SquareTextField(
        child: TextFormField(
            keyboardType: TextInputType.name,
            controller: _lastNameController,
            validator: validatorFor(alphaValidator, translations),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: squareInputDecoration(translations.name, Icons.person)));
  }

  Widget _buildPhoneField(size) {
    final translations = AppLocalizations.of(context);
    return SquareTextField(
        child: TextFormField(
            keyboardType: TextInputType.phone,
            controller: _phoneController,
            validator: validatorFor(numValidator, translations),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: squareInputDecoration(translations.signup.phone, Icons.phone)));
  }

  Widget _buildSignUpBtn() {
    final translations = AppLocalizations.of(context);
    return SquareButton(
      text: translations.signup.submit2,
      onPress: () => {
        if (_btnEnabled)
          signupCubit.trySignUp(
            signupAdditional.email,
            signupAdditional.password,
            _phoneController.text,
            _firstNameController.text,
            _lastNameController.text
          )
      },
      color: _btnEnabled ? kAccent : Colors.grey,
      textColor: Colors.white,
      width: 0.9,
    );
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _buildFirstNameField(size),
            _buildLastNameField(size),
            _buildPhoneField(size),
            SizedBox(height: 20.0),
            _buildSignUpBtn(),
            SizedBox(height: 10.0),
          ]
        )
      )
    );
  }
}
