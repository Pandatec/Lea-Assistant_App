import 'dart:convert';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Data/Models/CalendarEvent.dart';
import 'package:lea_connect/Screens/Core/Location/Views/location.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/patient_dashboard.dart';
import 'package:lea_connect/Utilities/timestamp.dart';
import 'package:lea_connect/Utilities/api_client.dart';

class PatientSession extends UserSession {
  final Patient patient;

  PatientSession(UserSession us, this.patient) :
    super(us.token, us.user);

  Future<APIResponse> getCalendarEvents({int? page, DateTime? date_begin, DateTime? date_end}) =>
    wsClient.request(token, 'GET', '/v1/patient/calendar_event/get', {
      "patientId": patient.id,
      ...(page != null ?
        {
          "page": page.toString()
        } :
        {
          "date_begin": dateTimeSecondsSinceEpoch(date_begin!).toString(),
          "date_end": dateTimeSecondsSinceEpoch(date_end!).toString(),
        }
      )
    }, {});

  Future<APIResponse> createCalendarEvent(String type, EventData data, DateTime date, String issuer) =>
    wsClient.request(token, 'POST', '/v1/patient/calendar_event/create', {
      'patientId': patient.id
    }, {
        "type": type,
        "datetime": dateTimeSecondsSinceEpoch(date),
        "duration": 1,
        "data": {"title": data.title, "desc": data.desc},
        "issuer": issuer
    });

  Future<APIResponse> editCalendarEvent(String calendarEventId, String type, EventData data, DateTime date, String issuer) =>
    wsClient.request(token, 'PATCH', '/v1/patient/calendar_event/edit', {
      'calendarEventId': calendarEventId
    }, {
        "type": type,
        "datetime": dateTimeSecondsSinceEpoch(date),
        "duration": 1,
        "data": {"title": data.title, "desc": data.desc},
        "issuer": issuer
    });

  Future<APIResponse> deleteCalendarEvent(String calendarEventId) =>
    wsClient.request(token, 'DELETE', '/v1/patient/calendar_event/delete', {
      'calendarEventId': calendarEventId
    }, {});

  Future<APIResponse> getPatientZones() => wsClient.request(token, 'GET', '/v1/patient/zones', {
    'patient_id': patient.id
  }, {});

  Future<APIResponse> checkHome() => wsClient.request(token, 'GET', '/v1/patient/home', {
    'patient_id': patient.id
  }, {});

  Future<APIResponse> patchPatientZone(Zone zone) => wsClient.request(token, 'PATCH', '/v1/patient/zone', {
    'patient_id': patient.id
  }, {
    'zone': zone.toJson()
  });

  Future<APIResponse> deletePatientZone(Zone zone) => wsClient.request(token, 'DELETE', '/v1/patient/zone', {
    'patient_id': patient.id,
    'zone_id': zone.id
  }, {});

  Future<APIResponse> getPatientMessages() => wsClient.request(token, 'GET', '/v1/patient/text-messages', {
    'patient_id': patient.id
  }, {});

  Future<APIResponse> createTextMessage(int datetime, String message) => wsClient.request(token, 'POST', '/v1/patient/text-message', {
    'patient_id': patient.id,
    'datetime': datetime.toString(),
    'message': message
  }, {});

  Future<APIResponse> playTextMessage(String messageId) => wsClient.request(token, 'PATCH', '/v1/patient/text-message', {
    'patient_id': patient.id,
    'message_id': messageId
  }, {});

  Future<APIResponse> getPatientEvents(int range_begin, int range_end) => wsClient.request(token, 'GET', '/v1/patient/events', {
    'patient_id': patient.id,
    'range_begin': range_begin.toString(),
    'range_end': range_end.toString()
  }, {});

  Future<APIResponse> getPatientZoneEvents(int range_begin, int range_end) => wsClient.request(token, 'GET', '/v1/patient/zone-events', {
    'patient_id': patient.id,
    'range_begin': range_begin.toString(),
    'range_end': range_end.toString()
  }, {});

  Future<APIResponse> getServicesMeta() => wsClient.request(token, 'GET', '/v1/patient/service/getMeta', {
    'patient_id': patient.id
  }, {});

  Future<APIResponse> getServices() => wsClient.request(token, 'GET', '/v1/patient/service/getAll', {
    'patient_id': patient.id
  }, {});

  Future<APIResponse> addService(Service service) => wsClient.request(token, 'POST', '/v1/patient/service/create', {
    'patient_id': patient.id,
    "trigger_type": EnumToString.convertToString(service.trigger),
    "trigger_payload": jsonEncode(service.trigger_payload),
    "action_type": EnumToString.convertToString(service.action),
    "action_payload": jsonEncode(service.action_payload),
  }, {});

  Future<APIResponse> patchService(Service service) => wsClient.request(token, 'PATCH', '/v1/patient/service/edit', {
    'patient_id': patient.id,
    'service_id': service.id,
    "trigger_payload": jsonEncode(service.trigger_payload),
    "action_type": EnumToString.convertToString(service.action),
    "action_payload": jsonEncode(service.action_payload),
  }, {});

  Future<APIResponse> deleteService(String serviceId) => wsClient.request(token, 'DELETE', '/v1/patient/service/delete', {
    'patient_id': patient.id,
    'service_id': serviceId
  }, {});
}