import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';

part 'patient_dashboard_state.dart';

class PatientDashboardCubit extends Cubit<PatientDashboardState> {

  PatientDashboardCubit() :
    super(PatientDashboardLoading());

  fetchIsFavorite(id) async {
    String? savedId = await authStorage.fetchPatientId();
    emit(PatientDashboardInitial(savedId == id));
  }
}
