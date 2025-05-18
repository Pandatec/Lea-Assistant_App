import 'package:lea_connect/Utilities/timestamp.dart';

class CalendarEvent {
  final String id;
  final String type;
  final DateTime date;
  final int duration;
  final EventData data;
  final String issuer;

  CalendarEvent(
      this.id, this.type, this.date, this.duration, this.data, this.issuer);

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
        json['id'],
        json['type'],
        dateTimeFromSecondsSinceEpoch(json['datetime']),
        json['duration'],
        EventData.fromJson(json["data"]),
        json['issuer']);
  }
}

class EventData {
  final String title;
  final String desc;

  EventData(this.title, this.desc);

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(json["title"], json["desc"]);
  }
}
