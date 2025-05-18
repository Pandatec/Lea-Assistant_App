import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class SpecialAddCard extends StatelessWidget {
  final void Function() onPress;

  SpecialAddCard({required this.onPress});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return DottedBorder(
        strokeWidth: 1,
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.1,
          decoration: BoxDecoration(),
          child: Center(
            child: IconButton(
              icon: Icon(Icons.add_rounded),
              onPressed: onPress,
            ),
          ),
        ));
  }
}
