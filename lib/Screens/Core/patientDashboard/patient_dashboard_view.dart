import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/patient_dashboard.dart';
import 'cubit/patient_dashboard_cubit.dart';

class PatientDashboardProvider extends StatelessWidget {
  final PatientSession session;

  PatientDashboardProvider(this.session, {Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PatientDashboardCubit>(
      create: (BuildContext context) => PatientDashboardCubit()..fetchIsFavorite(session.patient.id),
      child: PatientDashboardView(session)
    );
  }
}

class PatientDashboardView extends StatelessWidget {
  final PatientSession session;

  PatientDashboardView(this.session, {Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: BlocBuilder<PatientDashboardCubit, PatientDashboardState>(
        bloc: context.read<PatientDashboardCubit>(),
        builder: (context, state) {
          if (state is PatientDashboardLoading)
            return LoadingScreen();
          else if (state is PatientDashboardInitial)
            return PatientDashboard(session, state);
          else
            throw new Exception("PatientDashboardView: Unknown PatientDashboardState: ${state.toString()}");
        }
      )
    );
  }
}
