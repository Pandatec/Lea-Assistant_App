import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lea_connect/App.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Screens/auth/Login/Views/login_screen.dart';
import 'package:lea_connect/Screens/auth/Login/Views/login_view.dart';
import 'package:lea_connect/Screens/auth/Login/cubit/login_cubit.dart';
import 'package:lea_connect/Screens/auth/Signup/Screens/signup_additional_screen.dart';
import 'package:lea_connect/Screens/auth/Signup/Screens/signup_screen.dart';
import 'package:lea_connect/Screens/auth/Signup/Screens/signup_view.dart';
import 'package:lea_connect/Screens/auth/Signup/cubit/signup_cubit.dart';
import 'package:lea_connect/Screens/auth/Welcome/Views/welcome_view.dart';
import 'package:lea_connect/Screens/auth/Welcome/cubit/welcome_cubit.dart';
import 'package:lea_connect/Screens/auth/auth_view.dart';
import 'package:lea_connect/Screens/auth/cubit/auth_cubit.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lea_connect/l10n/localizations.dart';

void main() {
  MaterialApp createApp(Widget home) {
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }

  setUpAll(() {});

  group('Widget Authentication state', () {
    testWidgets('renders LoadingScreen when state is AppStart',
        (WidgetTester tester) async {
      final authCubit = AuthenticateCubit();
      await tester.pumpWidget(BlocProvider.value(
        value: authCubit,
        child: createApp(AppView()),
      ));

      authCubit.emit(AppStart());
      await tester.pump();
      expect(find.byType(LoadingScreen), findsOneWidget);
    });
    testWidgets('renders AuthView when state is Unauthenticated',
        (WidgetTester tester) async {
      final authCubit = AuthenticateCubit();
      await tester.pumpWidget(BlocProvider.value(
        value: authCubit,
        child: createApp(AppView()),
      ));

      authCubit.emit(Unauthenticated());
      await tester.pump();
      expect(find.byType(AuthView), findsOneWidget);
    });

    //Render Coreview when state is Authenticated
  });

  group('Welcome Screen widget state', () {
    testWidgets('renders LoadingScreen when state is WelcomeInital',
        (WidgetTester tester) async {
      final authCubit =
          AuthenticateCubit();
      final welcomeCubit = WelcomeCubit(authenticateCubit: authCubit);
      await tester.pumpWidget(BlocProvider.value(
        value: welcomeCubit,
        child: createApp(AuthView())
      ));

      welcomeCubit.emit(WelcomeInitial());
      await tester.pump();
      expect(find.byType(WelcomeView), findsOneWidget);
    });
    testWidgets('renders LoginView when state is SignIn',
        (WidgetTester tester) async {
      final authCubit = AuthenticateCubit();
      final welcomeCubit = WelcomeCubit(authenticateCubit: authCubit);
      await tester.pumpWidget(BlocProvider.value(
        value: welcomeCubit,
        child: createApp(AuthView()),
      ));

      welcomeCubit.emit(SignIn());
      await tester.pump();
      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('renders SignupView when state is SignUp',
        (WidgetTester tester) async {
      final authCubit =
          AuthenticateCubit();
      final welcomeCubit = WelcomeCubit(authenticateCubit: authCubit);
      await tester.pumpWidget(BlocProvider.value(
        value: welcomeCubit,
        child: createApp(AuthView()),
      ));

      welcomeCubit.emit(SignUp());
      await tester.pump();
      expect(find.byType(SignupView), findsOneWidget);
    });
  });

  group('Login Screen widget state', () {
    testWidgets('renders LoginScreen when state is LoginInitial',
        (WidgetTester tester) async {
      final authCubit =
          AuthenticateCubit();
      final welcomeCubit = WelcomeCubit(authenticateCubit: authCubit);
      final loginCubit = LoginCubit(welcomeCubit: welcomeCubit);
      await tester.pumpWidget(BlocProvider.value(
        value: loginCubit,
        child: createApp(LoginView()),
      ));

      loginCubit.emit(LoginInitial());
      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('renders LoadingScreen when state is LoginLoading',
        (WidgetTester tester) async {
      final authCubit = AuthenticateCubit();
      final welcomeCubit = WelcomeCubit(authenticateCubit: authCubit);
      final loginCubit = LoginCubit(welcomeCubit: welcomeCubit);
      await tester.pumpWidget(BlocProvider.value(
        value: loginCubit,
        child: createApp(LoginView()),
      ));

      loginCubit.emit(LoginLoading());
      await tester.pump();
      expect(find.byType(LoadingScreen), findsOneWidget);
    });
  });

  group('Signup Screen widget state', () {
    testWidgets('renders SignupScreen when state is SignupInitial',
        (WidgetTester tester) async {
      final authCubit = AuthenticateCubit();
      final welcomeCubit = WelcomeCubit(authenticateCubit: authCubit);
      final signupCubit = SignupCubit(welcomeCubit: welcomeCubit);
      await tester.pumpWidget(BlocProvider.value(
        value: signupCubit,
        child: createApp(SignupView()),
      ));

      signupCubit.emit(SignupInitial());
      await tester.pump();
      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('renders LoadingScreen when state is SignupLoading',
        (WidgetTester tester) async {
      final authCubit =
          AuthenticateCubit();
      final welcomeCubit = WelcomeCubit(authenticateCubit: authCubit);
      final signupCubit = SignupCubit(welcomeCubit: welcomeCubit);
      await tester.pumpWidget(BlocProvider.value(
        value: signupCubit,
        child: createApp(SignupView()),
      ));

      signupCubit.emit(SignupLoading());
      await tester.pump();
      expect(find.byType(LoadingScreen), findsOneWidget);
    });

    testWidgets('renders SignupAditionalScreen when state is SignupAditional',
        (WidgetTester tester) async {
      final authCubit =
          AuthenticateCubit();
      final welcomeCubit = WelcomeCubit(authenticateCubit: authCubit);
      final signupCubit = SignupCubit(
          welcomeCubit: welcomeCubit);
      await tester.pumpWidget(BlocProvider.value(
        value: signupCubit,
        child: createApp(SignupView()),
      ));

      signupCubit.emit(SignupAdditional(email: "email", password: "password"));
      await tester.pump();
      expect(find.byType(SignupAdditionalScreen), findsOneWidget);
    });
  });
}