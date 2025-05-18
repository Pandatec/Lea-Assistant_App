import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';
import 'package:lea_connect/Utilities/api_client.dart';

part 'signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  WelcomeCubit welcomeCubit;

  SignupCubit({required this.welcomeCubit}) :
    super(SignupInitial());

  Future<void> trySignUp(String email, String password, String phone, String firstName, String lastName, {repo: const UserRepository()}) async {
    emit(SignupLoading());
    final res = await repo.signUp(email, password, phone, firstName, lastName);
    either(null, res)((v) {
      welcomeCubit.emit(SignIn());
    }, (e) {
        emit(SignupInitial(email: email, errorMessage: e.msg));
    });
  }
}
