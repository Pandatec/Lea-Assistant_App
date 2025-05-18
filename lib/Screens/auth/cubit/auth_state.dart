part of 'auth_cubit.dart';

@immutable
abstract class AuthenticateState extends Equatable {}

class AppStart extends AuthenticateState {
  @override
  List<Object> get props => [];
}

class Authenticated extends AuthenticateState {
  final String email;
  final String token;
  final User user;

  Authenticated(this.email, this.token, this.user);

  @override
  List<Object> get props => [token];
}

class Unauthenticated extends AuthenticateState {
  @override
  List<Object> get props => [];
}

class Unverified extends AuthenticateState {
  final String email;
  final String token;
  final User user;

  Unverified(this.email, this.token, this.user);

  @override
  List<Object> get props => [token];
}

class Outdated extends AuthenticateState {
  @override
  List<Object> get props => [];
}
