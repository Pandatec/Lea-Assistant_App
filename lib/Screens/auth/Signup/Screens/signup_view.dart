import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Screens/auth/Signup/Screens/signup_additional_screen.dart';
import 'package:lea_connect/Screens/auth/Signup/Screens/signup_screen.dart';
import 'package:lea_connect/Screens/auth/Signup/cubit/signup_cubit.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';

class SignupProvider extends StatelessWidget {
  SignupProvider({Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignupCubit(
          welcomeCubit: context.read<WelcomeCubit>()
      ),
      child: SignupView(),
    );
  }
}

class SignupView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignupCubit, SignupState>(
      bloc: context.read<SignupCubit>(),
      builder: (context, state) {
        if (state is SignupInitial)
          return SignupScreen(state);
        else if (state is SignupLoading)
          return LoadingScreen();
        else if (state is SignupAdditional)
          return SignupAdditionalScreen(state);
        else
          throw new Exception("SignupView: Unknown SignupState: ${state.toString()}");
      });
  }
}
