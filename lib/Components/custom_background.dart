import 'package:flutter/material.dart';
import 'package:lea_connect/Constants/style.dart';

class CustomBackground extends StatelessWidget {
  final Widget? child;

  CustomBackground({Key? key, this.child}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
            alignment: Alignment.center,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kGradientStart,
                  kGradientMid,
                  kGradientEnd,
                ],
                end: Alignment.topRight,
                begin: Alignment.centerLeft,
              ),
            ),
            child: child));
  }
}

class CustomBackgroundLinear extends StatelessWidget {
  final Widget? child;

  CustomBackgroundLinear({Key? key, this.child}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
            alignment: Alignment.center,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kGradientStart,
                  kGradientMid,
                  kGradientEnd,
                ],
                end: Alignment.bottomRight,
                begin: Alignment.topLeft,
              ),
            ),
            child: child));
  }
}

class CustomBackgroundHome extends StatelessWidget {
  final Widget? child;

  CustomBackgroundHome({Key? key, this.child}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
            alignment: Alignment.center,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kGradientStart,
                  kGradientMid,
                  kGradientEnd,
                ],
                end: Alignment.topRight,
                begin: Alignment.bottomLeft,
              ),
            ),
            child: child));
  }
}
