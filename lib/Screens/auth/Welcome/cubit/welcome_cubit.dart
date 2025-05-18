import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Screens/auth/cubit/auth_cubit.dart';

part 'welcome_state.dart';

class WelcomeCubit extends Cubit<WelcomeState> {
  AuthenticateCubit authenticateCubit;

  WelcomeCubit({required this.authenticateCubit}) :
    super(WelcomeInitial());
}
