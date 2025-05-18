import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Components/outdated.dart';
import 'package:lea_connect/Components/unverified.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Screens/Core/core_view.dart';
import 'package:lea_connect/Screens/auth/auth_view.dart';
import 'package:lea_connect/Screens/auth/cubit/auth_cubit.dart';

class AppView extends StatelessWidget {
  AppView({Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: BlocBuilder<AuthenticateCubit, AuthenticateState>(
        bloc: context.read<AuthenticateCubit>(),
        builder: (context, state) {
          if (state is AppStart)
            return LoadingScreen();
          if (state is Outdated)
            return OutdatedScreen();
          else if (state is Unauthenticated)
            return AuthProvider();
          else if (state is Unverified)
            return UnverifiedScreen(UserSession(state.token, state.user));
          else if (state is Authenticated)
            return CoreProvider(UserSession(state.token, state.user));
          else
            throw new Exception("AppView: Unknown AuthenticateState: ${state.toString()}");
        }
      )
    );
  }
}

class PageAuthenticated extends StatelessWidget {
  PageAuthenticated({Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text("Authenticated")
    );
  }
}
