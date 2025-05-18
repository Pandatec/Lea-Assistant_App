import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Components/square_button.dart';
import 'package:lea_connect/Components/square_text_field.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/Utilities/validator.dart';
import 'package:lea_connect/l10n/localizations.dart';

class PatientPair extends StatefulWidget {
  final UserSession session;

  PatientPair(this.session);

  @override
  _PatientPairState createState() => _PatientPairState();
}

class _PatientPairState extends State<PatientPair> {
  UserSession get session => widget.session;

  static GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _codeController = TextEditingController();
  WsSubscription? sub;

  bool _btnEnabled = false;
  bool _onLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    sub?.cancel();
  }

  tryPairUser() {
    final translations = AppLocalizations.of(context);

    setState(() {
      _onLoading = true;
    });
    session.pairDevice(_codeController.text).then((value) {
      either(context, value)((v) async {
        sub = await wsRepository.listenOverride(WsSubscriptionKind.Pairing, (msg) {
          if (msg["type"] == "pairingAccepted") {
            sub!.cancel();
            sub = null;
            Navigator.of(context, rootNavigator: true).pop();
          } else {
            setState(() {
              _onLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content:
                Container(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Text(translations.patientPair.failed)
                )
              )
            );
          }
        });
      }, (e) {
        setState(() {
          _onLoading = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    Size size = MediaQuery.of(context).size;

    Widget _buildTitle() {
      return Text(translations.patientPair.inputCode,
          style: GoogleFonts.openSans(
              textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
    }

    Widget _buildCodeField() {
      return SquareTextField(
          child: TextFormField(
              validator: validatorFor(numValidator, translations),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.text,
              controller: _codeController,
              decoration: squareInputDecoration(translations.patientPair.code, Icons.dialpad)));
    }

    Widget _buildSaveBtn() {
      return SquareButton(
        text: translations.patientPair.submit,
        onPress: () {
          if (_btnEnabled)
            tryPairUser();
        },
        color: _btnEnabled ? kAccent : Colors.grey,
        textColor: Colors.white,
        width: 0.9,
      );
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: kSoftBackGround,
          foregroundColor: Colors.black,
          elevation: 0.0,
        ),
        body: _onLoading
            ? LoadingScreen()
            : Form(
                key: _formKey,
                onChanged: () => setState(
                    () => _btnEnabled = _formKey.currentState!.validate()),
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(color: kSoftBackGround),
                  child: Column(
                    children: <Widget>[
                      _buildTitle(),
                      SizedBox(height: 20.0),
                      _buildCodeField(),
                      _buildSaveBtn(),
                    ],
                  ),
                ),
              ));
  }
}
