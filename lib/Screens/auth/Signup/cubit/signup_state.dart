part of 'signup_cubit.dart';

@immutable
abstract class SignupState extends Equatable {}

class SignupInitial extends SignupState {
  final String email;
  final String? errorMessage;

  SignupInitial({this.email = "", this.errorMessage});
  @override
  List<Object?> get props => [email, errorMessage];
}

class SignupAdditional extends SignupState {
  final String email;
  final String password;

  SignupAdditional({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class SignupLoading extends SignupState {
  @override
  List<Object?> get props => [];
}
