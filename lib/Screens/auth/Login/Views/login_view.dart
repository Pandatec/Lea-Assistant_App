import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Screens/auth/Login/Views/login_screen.dart';
import 'package:lea_connect/Screens/auth/Login/cubit/login_cubit.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';

class LoginProvider extends StatelessWidget {
  LoginProvider({Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return (BlocProvider<LoginCubit>(
      create: (BuildContext context) => LoginCubit(
          welcomeCubit: context.read<WelcomeCubit>()
      ),
      child: LoginView()
    ));
  }
}

class LoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginCubit, LoginState>(
      bloc: context.read<LoginCubit>(),
      builder: (context, state) {
        if (state is LoginInitial)
          return LoginScreen(state);
        else if (state is LoginLoading)
          return LoadingScreen();
        else
          throw new Exception("LoginView: Unknown LoginState: ${state.toString()}");
      });
  }
}
