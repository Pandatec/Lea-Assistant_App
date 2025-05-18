import 'package:flutter/material.dart';

class Patient {
  String id;
  String firstName;
  String lastName;
  String nickName;
  String birthdate;
  String state;

  bool isConnected;
  double? batteryLevel;

  Patient({required this.id, required this.firstName, required this.lastName, required this.nickName, required this.birthdate, required this.state,
    this.isConnected = false,
    this.batteryLevel = null
  });

  Color stateColorBase() {
    if (state == 'home')
      return Colors.lightBlue;
    else if (state == 'safe')
      return Colors.lightGreen;
    else if (state == 'guard')
      return Colors.orange;
    else if (state == 'danger')
      return Colors.red;
    else if (state == 'unknown')
      return Colors.grey;
    else
      throw Exception("Unknown state ${state}");
  }

  Color stateColor() {
    final base = stateColorBase();
    return Color.fromARGB(192, base.red, base.green, base.blue);
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      nickName: json['nick_name'],
      birthdate: json['birth_date'],
      state: json['state'],
      isConnected: json['online'],
      batteryLevel: json['batteryLevel']?.toDouble()
    );
  }
}
