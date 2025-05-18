import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/Calendar/Views/calendar_list.dart';
import 'package:lea_connect/Screens/Core/Calendar/Views/calendar_monthly.dart';
import 'package:lea_connect/Screens/Core/Calendar/cubit/calendar_cubit.dart';

class CalendarProvider extends StatelessWidget {
  final PatientSession session;

  CalendarProvider(this.session, {Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CalendarCubit>(
        create: (BuildContext context) => CalendarCubit(session),
        child: CalendarView(session));
  }
}

class CalendarView extends StatelessWidget {
  final PatientSession session;

  CalendarView(this.session, {Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: BlocBuilder<CalendarCubit, CalendarState>(
        bloc: context.read<CalendarCubit>(),
        builder: (context, state) {
          if (state is CalendarMonthlyState)
            return CalendarMonthly(session);
          if (state is CalendarListState)
            return CalendarList(session);
          else if (state is CalendarLoading)
            return LoadingScreen();
          else
            throw new Exception("CalendarView: Unknown CalendarState: ${state.toString()}");
        },
      ),
    );
  }
}
