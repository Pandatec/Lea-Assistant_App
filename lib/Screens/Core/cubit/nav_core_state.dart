part of 'nav_core_cubit.dart';

@immutable
abstract class NavCoreState extends Equatable {}

class NavCoreLoading extends NavCoreState {
  @override
  List<Object> get props => [];
}

class NavCoreLoadedPatient extends NavCoreState {
  final User user;
  final Patient patient;
  final Pages initialPage;

  NavCoreLoadedPatient(this.user, this.patient,
      {this.initialPage = Pages.home});

  @override
  List<Object?> get props => [user, patient];
}

class NavCoreLoadedNoPatient extends NavCoreState {
  final User user;

  NavCoreLoadedNoPatient(this.user);

  @override
  List<Object?> get props => [user];
}
