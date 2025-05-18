import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Data/Models/Auth.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';
import 'package:lea_connect/Utilities/api_client.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  WelcomeCubit welcomeCubit;

  LoginCubit({required this.welcomeCubit}) :
    super(LoginInitial());

  Future<void> trySignIn(String email, String password, bool staySigned, {repo: const UserRepository()}) async {
    emit(LoginLoading());
    final res = await repo.signIn(email, password);
    either(null, res)((v) async {
      var auth = Auth(email, v['access_token']);
      await welcomeCubit.authenticateCubit.tryLoginFromAuth(auth, staySigned);
    }, (e) {
      emit(LoginInitial(errorMessage: e.msg));
    });
  }
}
