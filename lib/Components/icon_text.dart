import 'package:flutter/material.dart';

class IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final double size;

  IconText(
      {required this.icon,
      required this.text,
      this.color = Colors.black,
      this.size = 15});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: size,
        ),
        SizedBox(
          width: 10.0,
        ),
        Text(text, style: TextStyle(color: color, fontSize: size)),
      ],
    );
  }
}
