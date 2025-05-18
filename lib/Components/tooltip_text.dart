import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ToolTipText extends StatelessWidget {
  final String text;
  final double width;

  ToolTipText(this.text, {this.width = 0.85});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      width: size.width * width,
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoogleFonts.openSans(
            textStyle: TextStyle(color: Colors.black54, fontSize: 13),
          )),
    );
  }
}
