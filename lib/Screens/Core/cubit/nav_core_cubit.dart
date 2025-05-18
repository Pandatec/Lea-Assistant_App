import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/Data/Models/User.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Screens/auth/cubit/auth_cubit.dart';
import 'package:lea_connect/Screens/Core/Patient/Views/patient_form.dart';
import 'package:lea_connect/Utilities/api_client.dart';

import '../../../main.dart';

part 'nav_core_state.dart';

class NavCoreCubit extends Cubit<NavCoreState> {
  UserSession session;
  AuthenticateCubit authenticateCubit;

  NavCoreCubit(this.session, {required this.authenticateCubit}) :
    super(NavCoreLoading());

  Future<void> savePatient(Patient newPatient) {
    return authStorage.persistPatientId(newPatient.id);
  }

  Future<Map<String, dynamic>?> fetchUser() async {
    return session.getUser().then((value) {
      Map<String, dynamic>? res;
      eitherThen(null, value)((v) {
        res = v['user'];
      });
      return res;
    });
  }

  void loadUser(BuildContext? context) async {
    var src = await fetchUser();
    if (src == null) {
      authenticateCubit.emit(Unauthenticated());
      return null;
    } else {
      var user = User.fromJson(src);
      if (context != null) {
        App.of(context).applySettings(user.settings);
        await ensureNoInvalidPatients(user, context);
      }
      var id = await authStorage.fetchPatientId();
      Patient? patient;
      if (user.patients.isEmpty)
        emit(NavCoreLoadedNoPatient(user));
      try {
        if (id == null) {
          emit(NavCoreLoadedNoPatient(user));
          return;
        }
        // patient = user.patients.first;
        else
          patient = user.patients.firstWhere((element) => element.id == id);
        emit(NavCoreLoadedPatient(user, patient));
      } catch (IterableElementError) {
        print('Catch iterable error');
        emit(NavCoreLoadedNoPatient(user));
      }
      // no match
    }
  }

  // returns last modified patient if any was invalid, uses context to create form if needed
  Future<Patient?> ensureNoInvalidPatients(User user, BuildContext context) async {
    Patient? lastModif;
    for (var p in user.patients) {
      if (p.birthdate == "") {
        // default values
        p.birthdate = DateTime.now().toString();

        lastModif = await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PatientForm(session,
              patient: p,
              patientId: p.id,
            )
          ));
      }
    }
    if (lastModif != null) {
      updatePatients(lastModif);
      return lastModif;
    } else
      return null;
  }

  updateUser(Patient newPatient, {bool inList = false, Pages page = Pages.home}) {
    fetchUser().then((res) {
      if (res == null)
        authenticateCubit.emit(Unauthenticated());
      else {
        authStorage.persistPatientId(newPatient.id);
        emit(inList ?
          NavCoreLoadedNoPatient(User.fromJson(res)) :
          NavCoreLoadedPatient(User.fromJson(res), newPatient, initialPage: page)
        );
      }
    });
  }

  updateHome(Patient newPatient, Pages page) {
    updateUser(newPatient, page: page);
  }

  updateSettings(Patient newPatient) {
    updateUser(newPatient, page: Pages.profile);
  }

  updatePatients(Patient newPatient) {
    emit(NavCoreLoading());
    updateUser(newPatient);
  }

  updatePatientsList(Patient newPatient) {
    emit(NavCoreLoading());
    updateUser(newPatient, inList: true);
  }
}

enum Pages { profile, messenger, home, calendar, map }
