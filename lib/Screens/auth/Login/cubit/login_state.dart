part of 'login_cubit.dart';

@immutable
abstract class LoginState extends Equatable {}

class LoginInitial extends LoginState {
  final String? errorMessage;

  LoginInitial({this.errorMessage});
  @override
  List<Object?> get props => [errorMessage];
}

class LoginLoading extends LoginState {
  @override
  List<Object?> get props => [];
}
