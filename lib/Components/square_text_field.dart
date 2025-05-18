import 'package:flutter/material.dart';
import 'package:lea_connect/Constants/style.dart';

InputDecoration squareInputDecoration(String labeltext, IconData icon) {
  return InputDecoration(
      labelText: labeltext,
      labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      errorStyle: TextStyle(fontSize: 13, height: 0.8),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green),
        borderRadius: BorderRadius.circular(5.0),
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.black54,
      ));
}

InputDecoration squareInputDecorationPw(
    String labeltext, IconData icon, bool obscure, void Function() onPress) {
  return InputDecoration(
      labelText: labeltext,
      labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      errorStyle: TextStyle(fontSize: 13, height: 0.8),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green),
        borderRadius: BorderRadius.circular(5.0),
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.black54,
      ),
      suffixIcon: IconButton(
        onPressed: onPress,
        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
        color: Colors.black54,
      ));
}

class SquareTextField extends StatelessWidget {
  final Widget child;
  final double width;
  SquareTextField({Key? key, required this.child, this.width = 0.9}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        width: size.width * width,
        decoration: BoxDecoration(
            color: kPrimaryLightColor,
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(width: 1.0, color: Colors.grey)),
        child: child);
  }
}
