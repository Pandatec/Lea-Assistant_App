part of 'patient_dashboard_cubit.dart';

@immutable
abstract class PatientDashboardState extends Equatable {}

class PatientDashboardLoading extends PatientDashboardState {
  @override
  List<Object?> get props => [];
}

class PatientDashboardInitial extends PatientDashboardState {
  final bool isFavorite;

  PatientDashboardInitial(this.isFavorite);
  @override
  List<Object?> get props => [isFavorite];
}

class PatientDashboardGraph extends PatientDashboardState {
  final bool isFavorite;

  PatientDashboardGraph(this.isFavorite);
  @override
  List<Object?> get props => [isFavorite];
}

class PatientDashboardSettings extends PatientDashboardState {
  final bool isFavorite;

  PatientDashboardSettings(this.isFavorite);
  @override
  List<Object?> get props => [isFavorite];
}
