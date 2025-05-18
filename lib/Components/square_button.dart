import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Constants/style.dart';

class SquareButton extends StatelessWidget {
  final String text;
  final Color color, textColor;
  final void Function() onPress;
  final double width;
  final bool withBorder;

  SquareButton({
    Key? key,
    this.withBorder = false,
    required this.text,
    required this.onPress,
    this.color = kPrimaryColor,
    this.textColor = kPrimaryLightColor,
    this.width = 0.85
  }) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.06,
      width: size.width * width,
      child: TextButton(
        onPressed: onPress,
        child: Text(text,
            style: GoogleFonts.ubuntu(
                textStyle: TextStyle(color: textColor, fontSize: 18))),
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(color),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    side: withBorder
                        ? BorderSide(color: textColor, width: 1.0)
                        : BorderSide.none,
                    borderRadius: BorderRadius.circular(7.0)))),
      ),
    );
  }
}
