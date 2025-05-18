part of 'welcome_cubit.dart';

@immutable
abstract class WelcomeState {}

class WelcomeInitial extends WelcomeState {}

class SignIn extends WelcomeState {}

class ForgotPassword extends WelcomeState {}

class SignUp extends WelcomeState {}

