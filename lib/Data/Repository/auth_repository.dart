import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lea_connect/Constants/url.dart';
import 'package:lea_connect/Data/Models/Auth.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mutex/mutex.dart';

typedef WsOnDataHandler = void Function(Map<String, dynamic> event);

enum PatientEventClass {
  Location,
  BatteryLevel,
  Event,
  CalendarEvent
}

enum WsSubscriptionKind {
  NewNotification,
  NewNotificationCount,
  NewTextMessage,
  NewBatteryLevel,
  NewEvent,
  CalendarEvent,
  Pairing,
  Location,
  Verified,
  Else
}

class WsSubscription {
  final Mutex _mutex;
  final Set<WsOnDataHandler> _set;
  final WsOnDataHandler _listener;

  WsSubscription(this._mutex, Set<WsOnDataHandler> set, WsOnDataHandler listener) :
    _set = set,
    _listener = listener
  {
    _mutex.protect(() async {
      _set.add(_listener);
    });
  }

  void cancel() {
    _mutex.protect(() async {
      _set.remove(_listener);
    });
  }
}

class WsRepository {
  WebSocketChannel? _ws;
  Map<WsSubscriptionKind, Set<WsOnDataHandler>> _onWsData = {};
  bool _isWsConnected = false;
  Mutex _mutex = Mutex();
  Mutex _handlerMutex = Mutex();

  Set<WsOnDataHandler> getSetFor(WsSubscriptionKind kind) {
    final g = _onWsData[kind];
    if (g != null) {
      return g;
    } else {
      final res = Set<WsOnDataHandler>();
      _onWsData[kind] = res;
      return res;
    }
  }

  WsSubscription listen(WsSubscriptionKind kind, WsOnDataHandler listener) {
    return WsSubscription(_handlerMutex, getSetFor(kind), listener);
  }

  Future<WsSubscription> listenOverride(WsSubscriptionKind kind, WsOnDataHandler listener) async {
    await _handlerMutex.protect(() async {
      _onWsData.remove(kind);
    });
    return WsSubscription(_handlerMutex, getSetFor(kind), listener);
  }

  void emit(WsSubscriptionKind kind, Map<String, dynamic> msg) {
    _forwardMsgKind(msg, kind);
  }

  void _forwardMsgKind(Map<String, dynamic> msg, WsSubscriptionKind kind) {
    _handlerMutex.protect(() async {
      var ls = _onWsData[kind];
      if (ls != null)
        for (final l in ls)
          l(msg);
    });
  }

  void _forwardMsg(Map<String, dynamic> msg) {
    var t = msg['type'] as String;
    if (t == 'newNotification')
      _forwardMsgKind(msg, WsSubscriptionKind.NewNotification);
    if (t == 'newNotificationCount')
      _forwardMsgKind(msg, WsSubscriptionKind.NewNotificationCount);
    else if (t == 'newTextMessage')
      _forwardMsgKind(msg, WsSubscriptionKind.NewTextMessage);
    else if (t == 'batteryLevel' || t == 'isOnline')
      _forwardMsgKind(msg, WsSubscriptionKind.NewBatteryLevel);
    else if (t == 'newEvent' || t == 'newZoneEvent')
      _forwardMsgKind(msg, WsSubscriptionKind.NewEvent);
    else if (t == 'calendarEvent')
      _forwardMsgKind(msg, WsSubscriptionKind.CalendarEvent);
    else if (t == 'pairingAccepted' || t == 'pairingDenied')
      _forwardMsgKind(msg, WsSubscriptionKind.Pairing);
    else if (t == 'locationPosition' || t == 'locationDiag')
      _forwardMsgKind(msg, WsSubscriptionKind.Location);
    else if (t == 'userVerified')
      _forwardMsgKind(msg, WsSubscriptionKind.Verified);
    else
      _forwardMsgKind(msg, WsSubscriptionKind.Else);
  }

  static final _eventClass = {
    PatientEventClass.Location: 'Location',
    PatientEventClass.BatteryLevel: 'BatteryLevel',
    PatientEventClass.Event: 'Event',
    PatientEventClass.CalendarEvent: 'CalendarEvent',
  };

  // Event class to patient ID
  final _subEvents = Map<PatientEventClass, String>();
  final _subEventsCount = Map<PatientEventClass, int>();

  void enable(String patientId, PatientEventClass eventClass) {
    if (_subEvents[eventClass] != null)
      if (_subEvents[eventClass] != patientId)
        throw Exception("Another patient is already being listened to for such class!");
    if (_subEvents[eventClass] == patientId) {
      _subEventsCount.update(eventClass, (value) => value + 1);
      return;
    }
    _subEvents[eventClass] = patientId;
    _subEventsCount[eventClass] = 1;
    _ws?.sink.add(jsonEncode({
      "type": "enable${_eventClass[eventClass]}",
      "patientId": _subEvents[eventClass]
    }));
  }

  void disable(PatientEventClass eventClass) {
    _subEventsCount.update(eventClass, (value) => value - 1);
    if (_subEventsCount[eventClass]! > 0)
      return;
    _subEvents.remove(eventClass);
    _subEventsCount.remove(eventClass);
    _ws?.sink.add(jsonEncode({
      "type": "disable${_eventClass[eventClass]}"
    }));
  }

  void sendInitMsgs(Auth auth) {
    _ws?.sink.add(jsonEncode({
      "type": "login",
      "email": auth.email,
      "token": auth.token
    }));
  }

  void login(Auth auth) async {
    bool isAuthValid = true;
    _mutex.protect(() async {
      _ws?.sink.close();
      _ws = null;
      _isWsConnected = false;
      final w = WebSocketChannel.connect(
        Uri.parse(host.toWS()),
      );
      log("/app: connecting..");
      _ws = w;
      w.stream.listen((message) {
        _mutex.protect(() async {
          Map<String, dynamic> m = jsonDecode(message);
          if (_isWsConnected) {
            _forwardMsg(m);
          } else {
            if (m["type"] == "tokenAccepted") {
              _isWsConnected = true;
              for (final e in _subEvents.keys)
                _ws?.sink.add(jsonEncode({
                  "type": "enable${_eventClass[e]}",
                  "patientId": _subEvents[e]
                }));
            } else
              logout();
          }
        });
      }, onError: (err) async {
        log("/app: done, err.");
        await logout();
        await Future.delayed(Duration(seconds: 2));
        login(auth);
      });
      w.sink.done.then((value) async {
        log("/app: done.");
        bool reconn = false;
        await _mutex.protect(() async {
          if (w.closeReason == 'BAD_LOGIN')
            isAuthValid = false;
          if (_ws != null)
            _ws = null;
          reconn = isAuthValid;
        });
        if (reconn) {
          await Future.delayed(Duration(seconds: 2));
          login(auth);
        }
      });
      sendInitMsgs(auth);
    });
  }

  Future<void> logout() async {
    await _mutex.protect(() async {
      _ws?.sink.close();
      _ws = null;
    });
  }
}

var wsRepository = new WsRepository();

class AuthStorage {
  final String _tokenStorageLabel = 'access_token';
  final String _patientIdStorageLabel = 'patient_id';
  final _storage = const FlutterSecureStorage();

  const AuthStorage();

  Future<void> persistAuth(Auth auth) {
    return _storage.write(key: _tokenStorageLabel, value: jsonEncode({
      "email": auth.email,
      "token": auth.token
    }));
  }

  Future<Auth?> fetchAuth() {
    return _storage.read(key: _tokenStorageLabel).then((value) {
      if (value == null)
        return null;
      try {
        Map<String, dynamic> d = jsonDecode(value);
        return Auth(d["email"], d["token"]);
      } catch (FormatException) {
        return null;
      }
    });
  }

  Future<void> deleteToken() {
    return _storage.delete(key: _tokenStorageLabel);
  }

  Future<void> persistPatientId(String patientId) {
    return _storage.write(key: _patientIdStorageLabel, value: patientId);
  }

  Future<String?> fetchPatientId() {
    return _storage.read(key: _patientIdStorageLabel);
  }

  Future<void> deletePatientId() {
    return _storage.delete(key: _patientIdStorageLabel);
  }
}

final authStorage = AuthStorage();