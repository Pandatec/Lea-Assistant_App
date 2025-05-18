import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingScreen extends StatelessWidget {
  LoadingScreen({Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 300,
        height: 300,
        child: SpinKitFadingCircle(
          size: 100,
          itemBuilder: (BuildContext context, int index) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: index.isEven ? Colors.blueAccent : Colors.grey,
              ),
            );
          },
        ));
  }
}
