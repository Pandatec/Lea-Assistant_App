import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Screens/auth/Login/Views/login_view.dart';
import 'package:lea_connect/Screens/auth/Login/Views/forgot_password.dart';
import 'package:lea_connect/Screens/auth/Signup/Screens/signup_view.dart';
import 'package:lea_connect/Screens/auth/Welcome/Views/welcome_view.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';
import 'package:lea_connect/Screens/auth/cubit/auth_cubit.dart';

class AuthProvider extends StatelessWidget {
  AuthProvider({Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return (BlocProvider<WelcomeCubit>(
      create: (context) =>
          WelcomeCubit(authenticateCubit: context.read<AuthenticateCubit>()),
      child: AuthView(),
    ));
  }
}

class AuthView extends StatelessWidget {
  AuthView({Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: BlocBuilder<WelcomeCubit, WelcomeState>(
        bloc: context.read<WelcomeCubit>(),
        builder: (context, state) {
          if (state is WelcomeInitial)
            return WelcomeView();
          else if (state is SignIn)
            return LoginProvider();
          else if (state is ForgotPassword)
            return ForgotPasswordScreen();
          else if (state is SignUp)
            return SignupProvider();
          else
            throw new Exception("AuthView: Unknown WelcomeState: ${state.toString()}");
        },
      ),
    );
  }
}
