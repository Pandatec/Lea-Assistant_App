part of 'calendar_cubit.dart';

@immutable
abstract class CalendarState extends Equatable {}

class CalendarMonthlyState extends CalendarState {
  @override
  List<Object> get props => [];
}

class CalendarListState extends CalendarState {
  @override
  List<Object> get props => [];
}

class CalendarLoading extends CalendarState {
  @override
  List<Object> get props => [];
}
