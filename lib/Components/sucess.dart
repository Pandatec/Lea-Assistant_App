import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  SuccessScreen({Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
        height: size.height,
        width: size.width,
        color: Color(0xFF12c06a),
        child: Image.asset(
          'assets/images/sucess.gif',
          fit: BoxFit.contain,
          height: double.infinity,
          width: double.infinity,
          alignment: Alignment.center,
        ));
  }
}
