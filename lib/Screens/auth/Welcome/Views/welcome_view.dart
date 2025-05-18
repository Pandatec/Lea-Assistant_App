import 'dart:developer';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

Widget _buildWelcomeBtn(WelcomeCubit welcomeCubit, BuildContext context) {
  Size size = MediaQuery.of(context).size;
  final translations = AppLocalizations.of(context);
  return Container(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Color.fromARGB(255, 255, 255, 255)),
            minimumSize: MaterialStateProperty.all(Size(size.width * 0.8, 40)),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
              )
            )
          ),
          child: Text(translations.welcome.newUser, style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 20)),
          onPressed: () => welcomeCubit.emit(SignUp()),
        ),
        SizedBox(height: 10.0),
        TextButton(
          child: Text(translations.welcome.alreadyHaveAccount, style: TextStyle(color: Colors.white, fontSize: 15),),
          onPressed: () => welcomeCubit.emit(SignIn()),
        )
      ],
    ),
  );
}


class WelcomeView extends StatefulWidget {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final welcomeCubit = context.read<WelcomeCubit>();

    final onboardingPagesList = [
      Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              image: DecorationImage(image:  AssetImage('assets/home/opt1.png'), fit: BoxFit.fill)
            ),
            child: Lottie.asset("assets/home/gps.json"),
          ),
          Padding(padding: EdgeInsets.only(top: 100), child: Text("Toujours en sureté", style: GoogleFonts.roboto(textStyle: TextStyle(color: Colors.white, fontSize: 33, fontWeight: FontWeight.w300)),),)
        ],
      ),
      Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              image: DecorationImage(image:  AssetImage('assets/home/opt2.png'), fit: BoxFit.fill)
            ),
            child: Lottie.asset("assets/home/messenging.json"),
          ),
          Padding(padding: EdgeInsets.only(top: 100), child: Text("Favoriser le contact", style: GoogleFonts.roboto(textStyle: TextStyle(color: Colors.white, fontSize: 33, fontWeight: FontWeight.w300)),),)
        ],
      ),
      Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              image: DecorationImage(image:  AssetImage('assets/home/opt3.png'), fit: BoxFit.fill)
            ),
            child: Lottie.asset("assets/home/calendar.json"),
          ),
          Padding(padding: EdgeInsets.only(top: 100), child: Text("Garder le controle", style: GoogleFonts.roboto(textStyle: TextStyle(color: Colors.white, fontSize: 33, fontWeight: FontWeight.w300)),),)
        ],
      )
    ];

    pageChanged(int idx, CarouselPageChangedReason reason) => setState(() {
      _index = idx;
    });

    return Scaffold(
      body: Container(
        height: size.height,
        width: size.width,
        child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: size.height,
              viewportFraction: 1,
              initialPage: 0,
              enableInfiniteScroll: true,
              reverse: false,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 10),
              autoPlayAnimationDuration: Duration(milliseconds: 1000),
              autoPlayCurve: Curves.fastOutSlowIn,
              onPageChanged: pageChanged
            ),
            items: onboardingPagesList,
          ),
          Positioned(child: _buildWelcomeBtn(welcomeCubit, context), bottom: 30),
          Positioned(
            top: 45,
            child: Row(
              children: [
                Container(
                  width: size.width * 0.2,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(_index != 0 ? 0xFFF7F7F7 : 0xFF970EBB),
                    shape: BoxShape.circle
                  ),
                ),
                Container(
                  width: size.width * 0.2,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(_index != 1 ? 0xFFF7F7F7 : 0xFFCD0CE8),
                    shape: BoxShape.circle
                  ),
                ),
                Container(
                  width: size.width * 0.2,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(_index != 2 ? 0xFFF7F7F7 : 0xFF14E1A6),
                    shape: BoxShape.circle
                  ),
                ),
              ],
            )
          ),
        ],
      ),
      )
    );
  }
}

