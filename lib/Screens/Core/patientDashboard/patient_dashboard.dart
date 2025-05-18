import 'dart:convert';
import 'dart:developer';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:gauges/gauges.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lea_connect/Components/charts/chart_holder.dart';
import 'package:lea_connect/Components/custom_background.dart';
import 'package:lea_connect/Constants/home.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Models/Patient.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/Bar.dart';
import 'package:lea_connect/Screens/Core/Patient/Views/patient_form.dart';
import 'package:lea_connect/Screens/Core/cubit/nav_core_cubit.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/Widgets/zone_timeline.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/minMap.dart';
import 'package:lea_connect/Utilities/age_calculator.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/Utilities/timestamp.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../../Components/square_text_field.dart';
import '../Home/Widgets/patient_status_card.dart';
import 'cubit/patient_dashboard_cubit.dart';

class PatientDashboard extends StatefulWidget {
  final PatientSession session;
  final PatientDashboardInitial pdInitial;

  PatientDashboard(this.session, this.pdInitial, {Key? key}) : super(key: key);

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

const List<List<String>> _zoneSafety = [['home', 'Domicile'], ['safe', 'Sûre'], ['danger', 'Dangereuse'], ['neutral', 'Zone neutre']];

enum TRIGGERS {
  INTENT,
  ZONE_TYPE_CHANGED,
  ZONE_CHANGED, //implem later
  PERIODIC,
  TIME_RANGE,
}

const Map<TRIGGERS, String> _triggerLabel = {
  TRIGGERS.INTENT: 'Demande vocale',
  TRIGGERS.PERIODIC: 'Périodique',
  TRIGGERS.ZONE_TYPE_CHANGED: 'Changement de type de zone',
  TRIGGERS.TIME_RANGE: 'Périodique avec durée',
};

enum ACTIONS {
  ASK_FORGOTTEN,
  LIST_FORGOTTEN,
  DELETE_FORGOTTEN,
  LOCK_NEUTRAL,
  GUIDE_HOME,
  SAY_MESSAGE,
  SAY_FORECAST,
  SAY_TIME,
  SAY_DATE
}

const Map<ACTIONS, String> _actionLabel = {
  ACTIONS.ASK_FORGOTTEN: "Proposer d'ajouter des oublis",
  ACTIONS.LIST_FORGOTTEN: 'Lister les oublis',
  ACTIONS.DELETE_FORGOTTEN: 'Supprimer les oublis',
  ACTIONS.LOCK_NEUTRAL: 'Verouiller les zones neutres',
  ACTIONS.GUIDE_HOME: 'Guider vers le domicile',
  ACTIONS.SAY_MESSAGE: 'Lire message',
  ACTIONS.SAY_FORECAST: 'Lire la météo',
  ACTIONS.SAY_TIME: 'Lire l\'heure',
  ACTIONS.SAY_DATE: 'Lire la date'
};

class Service {
  final String id;
  final TRIGGERS trigger;
  final dynamic trigger_payload;
  final ACTIONS action;
  final dynamic action_payload;

  Service(this.id, this.trigger, this.trigger_payload, this.action, this.action_payload);
}

class _Event {
  final DateTime date;
  final String type;

  _Event(this.date, this.type);

  factory _Event.fromJson(Map<String, dynamic> json) {
    return _Event(dateTimeFromSecondsSinceEpoch(json['date']), json['type']);
  }
}

class _ZoneEvent {
  final DateTime range_begin;
  final DateTime range_end;
  final String? zone_id;

  _ZoneEvent(this.range_begin, this.range_end, this.zone_id);

  factory _ZoneEvent.fromJson(Map<String, dynamic> json) {
    return _ZoneEvent(dateTimeFromSecondsSinceEpoch(json['range_begin']),
        dateTimeFromSecondsSinceEpoch(json['range_end']), json['zone_id']);
  }
}

class _HorizontalRadioOption<T> {
  final String display;
  final T value;

  _HorizontalRadioOption(this.display, this.value);
}

class _HorizontalRadio<T> extends StatefulWidget {
  final List<_HorizontalRadioOption<T>> options;
  final T defaultValue;
  final void Function(T value) onSelection;

  _HorizontalRadio(this.options, this.defaultValue, this.onSelection);

  @override
  _HorizontalRadioState createState() {
    return _HorizontalRadioState<T>(options, onSelection, defaultValue);
  }
}

class _HorizontalRadioState<T> extends State<_HorizontalRadio> {
  final List<_HorizontalRadioOption<T>> options;
  final void Function(T value) onSelection;
  T selectedValue;

  _HorizontalRadioState(this.options, this.onSelection, this.selectedValue);

  /*@override
  void initState() {
  }*/

  @override
  Widget build(BuildContext ctx) {
    return Container(
        alignment: Alignment.center,
        margin: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
        child: Wrap(
            children: options
                .map((o) => TextButton(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(40, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: o.value == selectedValue
                            ? Colors.black12
                            : Colors.white),
                    onPressed: () {
                      setState(() {
                        selectedValue = o.value;
                      });
                      onSelection(selectedValue);
                    },
                    child: Text(o.display)))
                .toList()));
  }
}

enum Page { settings, home, rapports, services }

enum Timeframe { _1d, _2d, _4d, _1w, _2w, _1m, _3m, _6m, _1y }

final Map<Timeframe, Duration> timeframeToDuration = {
  Timeframe._1d: Duration(days: 1),
  Timeframe._2d: Duration(days: 2),
  Timeframe._4d: Duration(days: 4),
  Timeframe._1w: Duration(days: 7),
  Timeframe._2w: Duration(days: 14),
  Timeframe._1m: DateTime(0, 1, 0).difference(DateTime(0, 0, 0)),
  Timeframe._3m: DateTime(0, 3, 0).difference(DateTime(0, 0, 0)),
  Timeframe._6m: DateTime(0, 6, 0).difference(DateTime(0, 0, 0)),
  Timeframe._1y: DateTime(1, 0, 0).difference(DateTime(0, 0, 0)),
};

final Map<Timeframe, Duration> timeframeToGranularity = {
  Timeframe._1d: Duration(hours: 1),
  Timeframe._2d: Duration(hours: 2),
  Timeframe._4d: Duration(hours: 4),
  Timeframe._1w: Duration(hours: 8),
  Timeframe._2w: Duration(hours: 12),
  Timeframe._1m: Duration(days: 1),
  Timeframe._3m: Duration(days: 3),
  Timeframe._6m: Duration(days: 6),
  Timeframe._1y: Duration(days: 12)
};

class AbstractEvent {
  final DateTime date;
  final num count;
  final Duration span;

  AbstractEvent(this.date, this.count, this.span);
}

class _PatientDashboardState extends State<PatientDashboard> {
  PatientSession get session => widget.session;
  PatientDashboardInitial get pdInitial => widget.pdInitial;

  late bool patientIsConnected;
  double? lastPatientBatteryLevel;
  late double? patientBatteryLevel;

  TextEditingController _controller = TextEditingController();

  List<Service> _services = [];
  late bool isFavorite;
  List<_Event> events = [];
  bool areEventsLoaded = false;
  List<_ZoneEvent> zoneEvents = [];
  Map<String, String> zoneNames = {};
  bool areZoneEventsLoaded = false;
  Timeframe selectedTimeframe = Timeframe._1w;
  String zoneAt = '';
  late WsSubscription _eventSub;

  late WsSubscription _sub;

  Page _currentPage = Page.home;

  @override
  void initState() {
    super.initState();
    _triggervalue = _triggerLabel.values.first;
    _actionValue = _actionLabel.values.first;
    isFavorite = pdInitial.isFavorite;
    patientIsConnected = session.patient.isConnected;
    patientBatteryLevel = session.patient.batteryLevel;
    lastPatientBatteryLevel = patientBatteryLevel;

    _TTimeHour.text = '12';
    _TTimeMinute.text = '30';

    _TTimeStartHour.text = '12';
    _TTimeStartMinute.text = '30';

    _TTimeEndHour.text = '14';
    _TTimeEndMinute.text = '30';

    _TIntent.text = 'time';

    update();
    wsRepository.enable(session.patient.id, PatientEventClass.Event);
    _eventSub = wsRepository.listen(WsSubscriptionKind.NewEvent, (event) {
      setState(() {
        if (event['type'] == 'newEvent')
          events.add(_Event.fromJson(event['data']));
        else if (event['type'] == 'newZoneEvent')
          zoneEvents.add(_ZoneEvent.fromJson(event['data']));
      });
    });

    wsRepository.enable(session.patient.id, PatientEventClass.BatteryLevel);
    _sub = wsRepository.listen(WsSubscriptionKind.NewBatteryLevel, (event) {
      var t = event['type'];
      if (t == 'batteryLevel') {
        var d = event['data'];
        setState(() {
          lastPatientBatteryLevel = patientBatteryLevel;
          patientBatteryLevel = d?.toDouble();
          // Prevent nonsense from happening
          if ((lastPatientBatteryLevel != null) &&
              (patientBatteryLevel != null) &&
              (lastPatientBatteryLevel != patientBatteryLevel))
            patientIsConnected = true;
        });
      } else if (t == 'isOnline') {
        setState(() {
          patientIsConnected = event['data'];
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();
    wsRepository.disable(PatientEventClass.BatteryLevel);
    _eventSub.cancel();
    wsRepository.disable(PatientEventClass.Event);
  }

  Future<void> update() async {
    final now = DateTime.now();
    final dur = timeframeToDuration[selectedTimeframe]!;
    final ev = await session.getPatientEvents(
        dateTimeSecondsSinceEpoch(now.subtract(dur)),
        dateTimeSecondsSinceEpoch(now));
    eitherThen(context, ev)((v) {
      setState(() {
        events = (v['patient_events'] as List<dynamic>)
            .map((v) => _Event.fromJson(v))
            .toList();
        areEventsLoaded = true;
      });
    });
    final zev = await session.getPatientZoneEvents(
        dateTimeSecondsSinceEpoch(now.subtract(dur)),
        dateTimeSecondsSinceEpoch(now));
    eitherThen(context, zev)((v) {
      setState(() {
        zoneEvents = (v['patient_zone_events'] as List<dynamic>)
            .map((v) => _ZoneEvent.fromJson(v))
            .toList();
        zoneNames = {};
        for (final z in v['zones'] as List<dynamic>)
          zoneNames[z['id']] = z['name'];
        areZoneEventsLoaded = true;
      });
    });

    final services = await session.getServices();
    eitherThen(context, services)((ve) {
      setState(() {
        _services = [];
        final List<dynamic> r = ve['patient'];
        for (var service in r) {
          _services.add(
            Service(
              service['id'],
              EnumToString.fromString(TRIGGERS.values, service['trigger']['type'])!,
              service['trigger']['payload'],
              EnumToString.fromString(ACTIONS.values, service['action']['type'])!,
              service['action']['payload']
            ),
          );
          inspect(_services);
        }
      });
    });
  }

  togglePatientEdit() async {
    Patient? res = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PatientForm(session,
            patient: session.patient, patientId: session.patient.id)));
    if (res != null)
      setState(() {
        context.read<NavCoreCubit>().emit(NavCoreLoadedPatient(
            session.user, res,
            initialPage: Pages.messenger));
      });
  }

  updateFavorite() async {
    if (isFavorite) {
      await authStorage.deletePatientId();
      setState(() {
        isFavorite = false;
      });
    } else {
      await authStorage.persistPatientId(session.patient.id);
      setState(() {
        isFavorite = true;
      });
    }
  }

  Map<String, List<AbstractEvent>> getFeatureData() {
    final Map<String, List<AbstractEvent>> base = {};
    for (final e in events) {
      if (base[e.type] == null) base[e.type] = [];
      base[e.type]!.add(AbstractEvent(e.date, 1, Duration()));
    }
    final Map<String, List<AbstractEvent>> res = {};
    for (final e in base.entries)
      res[localizePatientEventType(context, e.key)] = e.value;
    return res;
  }

  Map<String, List<AbstractEvent>> getSuccessData() {
    final Map<String, List<AbstractEvent>> base = {
      'success': [],
      'failure': [],
    };
    for (final e in events) {
      final k = e.type == 'unknown' ? 'failure' : 'success';
      if (base[k] == null) base[k] = [];
      base[k]!.add(AbstractEvent(e.date, 1, Duration()));
    }
    final Map<String, List<AbstractEvent>> res = {};
    for (final e in base.entries)
      res[localizePatientEventSuccess(context, e.key)] = e.value;
    return res;
  }

  Map<String, List<AbstractEvent>> getZoneRateData() {
    final translations = AppLocalizations.of(context);
    final Map<String, List<AbstractEvent>> base = {};
    for (final e in zoneEvents) {
      final k = e.zone_id != null ? e.zone_id! : 'null';
      if (base[k] == null) base[k] = [];
      final len = e.range_end.difference(e.range_begin);
      base[k]!.add(AbstractEvent(
          e.range_begin, len.inMilliseconds.toDouble() / (1000.0 * 60.0), len));
    }
    final Map<String, List<AbstractEvent>> res = {};
    for (final e in base.entries) {
      final zn = zoneNames[e.key];
      res[zn != null
          ? zn
          : translations.patientDashboard.zoneRate.unclassified] = e.value;
    }
    return res;
  }

  String getZoneAt(DateTime date) {
    final translations = AppLocalizations.of(context);
    for (final e in zoneEvents)
      if (date.isAfter(e.range_begin) && date.isBefore(e.range_end)) {
        final zn = zoneNames[e.zone_id];
        return zn != null
            ? zn
            : translations.patientDashboard.zoneRate.unclassified;
      }
    return translations.patientDashboard.zonePos.offline;
  }

  getMeta() async {
    final meta = await session.getServicesMeta();
    final services = await session.getServices();

    eitherThen(context, meta)((v) {
      inspect(v);
    });

    eitherThen(context, services)((v) {
      inspect(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);

    Widget _buildPatientCard() {
      return Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 10,
            ),
            PatientStatusCard(
                session: session,
                title: session.patient.nickName,
                isConnected: patientIsConnected,
                battery: patientBatteryLevel,
                state: session.patient.state)
          ]));
    }

    Widget _buildProfile() {
      return Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 40),
          child: Row(
            children: [
              ClipOval(
                  child: Image.network(
                "https://picsum.photos/200",
                fit: BoxFit.cover,
                width: 80,
                height: 80,
              )),
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${session.patient.nickName}',
                        style: GoogleFonts.openSans(
                          textStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontFamily: 'Open-Sans'),
                        )),
                    Text(
                      '${session.patient.lastName} ${session.patient.firstName} | ${calculateAge(DateTime.parse(session.patient.birthdate))} ${translations.full_years}',
                      style: GoogleFonts.openSans(
                        textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Open-Sans'),
                      ),
                    )
                  ],
                ),
              )
            ],
          ));
    }

    Widget _buildGraph() {
      final ttf = translations.patientDashboard.timeframe;
      Size size = MediaQuery.of(context).size;

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _HorizontalRadio<Timeframe>([
          _HorizontalRadioOption(ttf.t1d, Timeframe._1d),
          _HorizontalRadioOption(ttf.t2d, Timeframe._2d),
          _HorizontalRadioOption(ttf.t4d, Timeframe._4d),
          _HorizontalRadioOption(ttf.t1w, Timeframe._1w),
          _HorizontalRadioOption(ttf.t2w, Timeframe._2w),
          _HorizontalRadioOption(ttf.t1m, Timeframe._1m),
          _HorizontalRadioOption(ttf.t3m, Timeframe._3m),
          _HorizontalRadioOption(ttf.t6m, Timeframe._6m),
          _HorizontalRadioOption(ttf.t1y, Timeframe._1y)
        ], Timeframe._1w, (Timeframe timeframe) {
          selectedTimeframe = timeframe;
          update();
        }),
        ChartHolder(getFeatureData(), selectedTimeframe,
            title: translations.patientDashboard.typeUsageChart.title,
            desc: translations.patientDashboard.typeUsageChart.desc),
        SizedBox(
          height: 40,
        ),
        ChartHolder(getSuccessData(), selectedTimeframe,
            title: translations.patientDashboard.usageSuccess.title,
            desc: translations.patientDashboard.usageSuccess.desc),
        ChartHolder(getZoneRateData(), selectedTimeframe,
            title: translations.patientDashboard.zoneRate.title,
            desc: translations.patientDashboard.zoneRate.desc),
        SizedBox(
          height: 40,
        ),
        Container(
            padding: EdgeInsets.all(16.0),
            child: Column(children: [
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    translations.patientDashboard.zonePos.title,
                    style: GoogleFonts.openSans(
                        textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    )),
                  ),
                  Text(
                    translations.patientDashboard.zonePos.desc,
                    style: TextStyle(fontSize: 12),
                  ),
                ])
              ]),
              SizedBox(
                height: 20,
              ),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(
                      width: size.width * 0.9,
                      height: size.height * 0.3,
                      child: ZoneTimeline(getZoneRateData(), selectedTimeframe))
                ])
              ])
            ])),
        SizedBox(
          height: 40,
        ),
      ]);
    }

    Widget _buildBatteryLevel() {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Card(
          elevation: 15.0,
          child: ListTile(
          leading: RadialGauge(
            axes: [
              RadialGaugeAxis(
                pointers: [
                  RadialNeedlePointer(
                      value: patientBatteryLevel != null ? patientBatteryLevel! * 100 : 0,
                      thicknessStart: 20,
                      thicknessEnd: 0,
                      length: 0.6,
                      knobRadiusAbsolute: 10,
                      gradient: LinearGradient(
                        colors: [
                          kGradientStart,
                          kGradientMid,
                          kGradientEnd,
                        ],
                        end: Alignment.topRight,
                        begin: Alignment.centerLeft,
                      ))
                ],
                color: Colors.transparent,
                minValue: 0,
                maxValue: 100,
                segments: [
                  RadialGaugeSegment(
                    minValue: 0,
                    maxValue: 20,
                    minAngle: -130,
                    maxAngle: -78,
                    color: Colors.red,
                  ),
                  RadialGaugeSegment(
                    minValue: 20,
                    maxValue: 40,
                    minAngle: -78,
                    maxAngle: -26,
                    color: Colors.orange,
                  ),
                  RadialGaugeSegment(
                    minValue: 40,
                    maxValue: 60,
                    minAngle: -26,
                    maxAngle: 26,
                    color: Color.fromARGB(255, 229, 205, 71),
                  ),
                  RadialGaugeSegment(
                    minValue: 60,
                    maxValue: 80,
                    minAngle: 26,
                    maxAngle: 78,
                    color: Color.fromARGB(255, 91, 201, 27),
                  ),
                  RadialGaugeSegment(
                    minValue: 80,
                    maxValue: 100,
                    minAngle: 78,
                    maxAngle: 130,
                    color: Color.fromARGB(255, 113, 177, 53),
                  ),
                  // ...
                ],
              ),
            ],
          ),
          title: Text("État de la batterie", style: TextStyle(fontWeight: FontWeight.bold),),
          subtitle: Text('${(patientBatteryLevel == null ? 0.0 : patientBatteryLevel! * 100.0).toStringAsFixed(2)} %', style: TextStyle(fontSize: 15, color: Colors.black)),
          trailing: Column(
            children: [
              SizedBox(height: 7),
              Icon(
                Icons.wifi,
                color: patientIsConnected ? Colors.green : Colors.red[500],
              ),
              Text(patientIsConnected ? translations.online : translations.offline)
            ],
          ),
      ),
        ));
    }

    Widget _buildSendMessage() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 10,
            ),
            Hero(
                  tag: 'message_input',
                  child: Card(
                    elevation: 15.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTextField(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: "Dire bonjour",
                            hintStyle: TextStyle(color: Colors.grey),
                            contentPadding: EdgeInsets.all(12.0),
                          )
                        ),
                        width: 0.50,
                      ),
                    SizedBox(
                      width: 10,
                    ),
                    Container(
                      height: 48,
                      child: ElevatedButton(
                        child: Icon(Icons.send),
                        onPressed: () {
                          final t = _controller.text;
                          _controller.text = '';
                          homeKey.currentState!.updateInitialText(t);
                          homeKey.currentState!.updateIndex(Pages.messenger);
                        }
                      )
                    )
                  ]
                )
              )
            )
          ]
        )
      );
    }

    Widget _buildNews() {
      Size size = MediaQuery.of(context).size;
      return GestureDetector(
        child: Container(
        height: size.height * 0.4,
        padding: EdgeInsets.symmetric(horizontal: 30.0),
        child: Card(
          elevation: 15.0,
          child: Image.asset("assets/images/new.png"),
        ),
      ),
      );
    }

    Widget _buildHome() {
      return Column(
        children: [
          _buildBatteryLevel(),
          //_buildSendMessage(),
          SizedBox(
            height: 10.0,
          ),
          MiniMap(session),
          SizedBox(
            height: 10.0,
          ),
          _buildNews(),
          SizedBox(
            height: 10.0,
          ),
        ],
      );
    }

    Widget _buildSettings() {
      final size = MediaQuery.of(context).size;
      return _services.isEmpty 
      ? Container(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 64.0),
              child: Text("Aucun service créé pour le moment : cliquez sur + pour en ajouter !")
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _editMode = false;
                  _currentPage = Page.services;
                });
              },
              child: Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(15),
              ),
            ),
            SizedBox(height: size.height * 0.3, child: Lottie.asset('assets/home/empty.json'),),
          ],
        )
      ) :
      new SingleChildScrollView(
        child: Column(
          children: [
            Column(children:
              _services.map((s) {
                final Widget res = Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child:
                    Card(
                      elevation: 7,
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _editMode = true;
                            _editId = s.id;
                            setControllerForEdit(s);
                            _currentPage = Page.services;
                          });
                        },
                        title: Text('Déclencheur : ${_triggerLabel[s.trigger]!}'),
                        subtitle: Text('Action : ${_actionLabel[s.action]!}'),
                    )
                  )
                );
                return res;
              }).toList()
            ),
            SizedBox(height: 10,),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _editMode = false;
                  _currentPage = Page.services;
                });
              },
              child: Icon(Icons.add),
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(15),
              ),
            ),
            SizedBox(height: 48)
          ]
        )
      );
    }

    Widget _buildContent() {
      if (_currentPage == Page.home)
        return _buildHome();
      else if (_currentPage == Page.rapports) return _buildGraph();
      else if (_currentPage == Page.settings) return _buildSettings();
      else if (_currentPage == Page.services) return _buildServiceForm();
      return _buildHome();
    }

    Widget _buildBottomCard() {
      return Expanded(
          child: Container(
              transform: Matrix4.translationValues(0.0, -1.0, 0.0),
              child: SingleChildScrollView(child: _buildContent()),
              decoration: BoxDecoration(
                color: kPrimaryColor,
              )));
    }

    Widget _buildButtons() {
      return Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20.0),
                  topRight: const Radius.circular(20.0))),
          child: Container(
              transform: Matrix4.translationValues(0.0, -25.0, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /*Column(
                    children: [
                      ElevatedButton(
                        onPressed: togglePatientEdit,
                        child: Icon(Icons.edit),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                        ),
                      ),
                      Text(translations.patientList.optionEdit)
                    ],
                  ),
                  SizedBox(width: 60.0),*/
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentPage = Page.settings;
                          });
                        },
                        child: Icon(Icons.settings),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                        ),
                      ),
                      Text("Configuration")
                    ],
                  ),
                  SizedBox(width: 30.0),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentPage = Page.home;
                          });
                        },
                        child: Icon(Icons.home_max_outlined),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                        ),
                      ),
                      Text("Résumé")
                    ],
                  ),
                  SizedBox(width: 30.0),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentPage = Page.rapports;
                          });
                        },
                        child: Icon(Icons.leaderboard_outlined),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                        ),
                      ),
                      Text("Rapports")
                    ],
                  ),
                  /* Column(
                    children: [
                      ElevatedButton(
                        onPressed: updateFavorite,
                        child: Icon(
                          Icons.star,
                          color: isFavorite ? Colors.yellow : kPrimaryColor
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(15),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        child: Text(translations.favorite)
                      )
                    ],
                  ), */
                ],
              )));
    }

    return Scaffold(
      appBar: Bar(session, Icon(Icons.medical_services)),
      body: CustomBackground(
          child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [_buildProfile(), _buildButtons(), _buildBottomCard()],
        ),
      )),
    );
  }


  //Services

  bool _editMode = false;
  String _editId = '';
  String _triggervalue = '';
  dynamic _triggerPayload = {};

  String _actionValue = '';
  dynamic _actionPayload = {};

  //Intent
  TextEditingController _TIntent = TextEditingController();

  //ZoneTypeChanged
  String _TZoneIn = 'danger';
  String _TZoneOut = 'safe';

  //Periodic
  bool _TMon = false;
  bool _TTue= false;
  bool _TWen= false;
  bool _TThu = false;
  bool _TFri = false;
  bool _TSat = false;
  bool _TSun = false;

  TextEditingController _TTimeHour= TextEditingController();
  TextEditingController _TTimeMinute= TextEditingController();

  //TIME RANGE
  TextEditingController _TTimeStartHour= TextEditingController();
  TextEditingController _TTimeStartMinute= TextEditingController();

  TextEditingController _TTimeEndHour= TextEditingController();
  TextEditingController _TTimeEndMinute= TextEditingController();

  //ACTION
  TextEditingController _ASayMessage = TextEditingController();
  //TextEditingController _AListForgoten = TextEditingController();

  List<TextEditingController> _AListForgoten = [
    //TextEditingController()
  ];

  resetController() {
    _TZoneIn = 'danger';
    _TZoneOut = 'safe';

    _TMon = false;
    _TFri = false;
    _TThu = false;
    _TSat = false;
    _TTue = false;
    _TWen = false;
    _TSun = false;

    _TTimeHour.text = '12';
    _TTimeMinute.text = '30';

    _TTimeStartHour.text = '12';
    _TTimeStartMinute.text = '30';

    _TTimeEndHour.text = '14';
    _TTimeEndMinute.text = '30';

    _TIntent.text = 'time';

    _AListForgoten = [];
    _ASayMessage.text = '';

  }

  setControllerForEdit(Service service) {
    _actionValue = _actionLabel[service.action]!;
    _triggervalue = _triggerLabel[service.trigger]!;

    switch (service.trigger) {
      case TRIGGERS.INTENT:
        _TIntent.text = service.trigger_payload['intent'];
        break;
      case TRIGGERS.PERIODIC:
        _TMon = service.trigger_payload['activation_days']['mon'];
        _TTue = service.trigger_payload['activation_days']['tue'];
        _TWen = service.trigger_payload['activation_days']['wed'];
        _TThu = service.trigger_payload['activation_days']['thu'];
        _TFri = service.trigger_payload['activation_days']['fri'];
        _TSat = service.trigger_payload['activation_days']['sat'];
        _TSun = service.trigger_payload['activation_days']['sun'];
        _TTimeHour.text = service.trigger_payload['time']['hour'].toString();
        _TTimeMinute.text = service.trigger_payload['time']['minute'].toString();
        break;
      case TRIGGERS.TIME_RANGE:
        _TMon = service.trigger_payload['activation_days']['mon'];
        _TTue = service.trigger_payload['activation_days']['tue'];
        _TWen = service.trigger_payload['activation_days']['wed'];
        _TThu = service.trigger_payload['activation_days']['thu'];
        _TFri = service.trigger_payload['activation_days']['fri'];
        _TSat = service.trigger_payload['activation_days']['sat'];
        _TSun = service.trigger_payload['activation_days']['sun'];
        _TTimeStartHour.text = service.trigger_payload['start']['hour'].toString();
        _TTimeStartMinute.text = service.trigger_payload['start']['minute'].toString();
        _TTimeEndHour.text = service.trigger_payload['end']['hour'].toString();
        _TTimeEndMinute.text = service.trigger_payload['end']['minute'].toString();
        break;
      case TRIGGERS.ZONE_TYPE_CHANGED:
        _TZoneIn = service.trigger_payload['zone_in'];
        _TZoneOut = service.trigger_payload['zone_out'];
        break;
      default:
        break;
    }

    switch (service.action) {
      case ACTIONS.LIST_FORGOTTEN:
        _AListForgoten = [];
        for (var item in service.action_payload['items']) {
          _AListForgoten.add(TextEditingController.fromValue(TextEditingValue(text: item)));
        }
        break;
      case ACTIONS.SAY_MESSAGE:

        _ASayMessage.text = service.action_payload['text'];
        break;
      default:
        break;
    }
  }

  generateService() async {
    TRIGGERS eqT = _triggerLabel.keys.firstWhere((el) => _triggerLabel[el] == _triggervalue);
    ACTIONS eqA = _actionLabel.keys.firstWhere((element) => _actionLabel[element] == _actionValue);

    switch (eqT) {
      case TRIGGERS.INTENT:
        _triggerPayload = {
          'intent': _TIntent.text
        };
        break;
      case TRIGGERS.ZONE_TYPE_CHANGED:
        _triggerPayload = {
          "zone_in": _TZoneIn,
          "zone_out": _TZoneOut
        };
        break;
      case TRIGGERS.PERIODIC:
        _triggerPayload = {
          "activation_days": {
            "mon": _TMon,
            "tue": _TTue,
            "wed": _TWen,
            "thu": _TThu,
            "fri": _TFri,
            "sat": _TSat,
            "sun": _TSun,
          },
          "time": {
            "hour": int.parse(_TTimeHour.text),
            "minute": int.parse(_TTimeMinute.text)
          }
        };
        break;
      case TRIGGERS.TIME_RANGE:
        _triggerPayload = {
          "activation_days": {
            "mon": _TMon,
            "tue": _TTue,
            "wed": _TWen,
            "thu": _TThu,
            "fri": _TFri,
            "sat": _TSat,
            "sun": _TSun,
          },
          "start": {
            "hour": int.parse(_TTimeStartHour.text),
            "minute": int.parse(_TTimeStartMinute.text),
          },
          "end": {
            "hour": int.parse(_TTimeEndHour.text),
            "minute": int.parse(_TTimeEndMinute.text)
          },
        };
        break;
      default:
        _triggerPayload = {
          'test': 'test'
        };
        break;
    };

    List<String> items = _AListForgoten.map((e) => e.text).toList();
    switch (eqA) {
      case ACTIONS.LIST_FORGOTTEN:
        _actionPayload = {
          'items': items
        };
        break;
      case ACTIONS.SAY_MESSAGE:
        _actionPayload = {
          'text': _ASayMessage.text
        };
        break;
      default:
        _actionPayload = {
          'test': 'test'
        };
        break;
    }

    Service serv = Service(_editMode ? _editId : '', eqT, _triggerPayload, eqA, _actionPayload);

    final servResp = _editMode ? await session.patchService(serv) : await session.addService(serv);

    eitherThen(context, servResp)((v) async {

      if (_editMode) {
        _services.removeWhere((element) => element.id == _editId);
      }
      final services = await session.getServices();
      eitherThen(context, services)((ve) {
        setState(() {
          _services = [];
          final List<dynamic> r = ve['patient'];
          for (var service in r) {
            _services.add(
              Service(
                service['id'],
                EnumToString.fromString(TRIGGERS.values, service['trigger']['type'])!,
                service['trigger']['payload'],
                EnumToString.fromString(ACTIONS.values, service['action']['type'])!,
                service['action']['payload'],
              )   
            );
          }
          resetController();
          _currentPage = Page.settings;
        });
      });
    });
  }

  deleteService() async {
    final resp = await session.deleteService(_editId);

    eitherThen(context, resp)((v) {
      resetController();
      setState(() {
        _services.removeWhere((element) => element.id == _editId);
        _currentPage = Page.settings;
      });
    });
  }

  Widget _buildServiceForm() {
    final size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Déclencheur', style: GoogleFonts.roboto(fontSize: 22),),
        DropdownButton(
          value: _triggervalue,
          items: _triggerLabel.values.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
          onChanged: _editMode ? null : (String? value) {
            setState(() {
              _triggervalue = value!;
            });
          },
        ),
        Container(
          width: size.width,
          child: _buildTriggerPayload(),
        ),
        SizedBox(height: 10.0,),
        Icon(Icons.arrow_downward, size: 40,),
        SizedBox(height: 10.0,),
        Text('Action', style: GoogleFonts.roboto(fontSize: 22),),
        DropdownButton(
          value: _actionValue,
          items: _actionLabel.values.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
          onChanged: _editMode ? null : (String? value) {
            setState(() {
              _actionValue = value!;
            });
          }
        ),
        Container(
          width: size.width,
          child: _buildActionPayload(),
        ),
        _editMode ? Container() : ElevatedButton(
          onPressed: () {
            generateService();
          },
          child: Text("Ajouter le service"),
        ),
        _editMode ? 
        ElevatedButton(
          onPressed: () {
            deleteService();
          },
          child: Text("Supprimer"),
        ) : Container(),
        ElevatedButton(
          onPressed: () {
            setState(() {
              resetController();
              _currentPage = Page.settings;
            });
          },
          child: Text("Annuler"),
        ),
        SizedBox(height: 40,),
      ],
    );
  }

  Widget _buildTriggerPayload() {
    final size = MediaQuery.of(context).size;
    if (_triggervalue == _triggerLabel[TRIGGERS.INTENT]) {
      return Column(
        children: [
          DropdownButton(
            value: _TIntent.text,
            items: [
              ["time", "Heure"],
              ["date", "Date"],
              ["forecast", "Météo"],
              ["list_forgotten", "Lister les oublis"],
              ["delete_forgotten", "Supprimer les oublis"],
              ["guide_home", "Rentrer à la maison"]
            ].map<DropdownMenuItem<String>>((List<String> value) {
                return DropdownMenuItem<String>(
                  value: value[0],
                  child: Text(value[1]),
                );
          }).toList(),
            onChanged: _editMode ? null : (String? value) {
              setState(() {
                _TIntent.text = value!;
              });
            },
          )
        ],
      );
    }
    else if (_triggervalue == _triggerLabel[TRIGGERS.ZONE_TYPE_CHANGED]) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton(
            value: _TZoneOut,
            items: _zoneSafety.map<DropdownMenuItem<String>>((List<String> value) {
              return DropdownMenuItem<String>(
                value: value[0],
                child: Text(value[1]),
              );
            }).toList(),
            onChanged: _editMode ? null : (String? value) {
              setState(() {
                _TZoneOut = value!;
              });
            }
          ),
          Icon(Icons.arrow_right, size: 55,),
          DropdownButton(
            value: _TZoneIn,
            items: _zoneSafety.map<DropdownMenuItem<String>>((List<String> value) {
              return DropdownMenuItem<String>(
                value: value[0],
                child: Text(value[1]),
              );
            }).toList(),
            onChanged: _editMode ? null : (String? value) {
              setState(() {
                _TZoneIn = value!;
              });
            }
          ),
        ],
      );
    }
    else if (_triggervalue == _triggerLabel[TRIGGERS.TIME_RANGE]) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text('Lun'),
                  Checkbox(
                    value: _TMon,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TMon = e!;
                      });
                    }
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Mar'),
                  Checkbox(
                    value: _TTue,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TTue = e!;
                      });
                    }
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Mer'),
                  Checkbox(
                    value: _TWen,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TWen = e!;
                      });
                    }
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Jeu'),
                  Checkbox(
                    value: _TThu,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TThu = e!;
                      });
                    }
                  ),
                ]
              ),
              Column(
                children: [
                  Text('Ven'),
                  Checkbox(
                    value: _TFri,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TFri = e!;
                      });
                    }
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Sam'),
                  Checkbox(
                    value: _TSat,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TSat = e!;
                      });
                    }
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Dim'),
                  Checkbox(
                    value: _TSun,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TSun = e!;
                      });
                    }
                  ),
                ],
              ),
            ],
          ),
          Text('Début', style: GoogleFonts.roboto(fontSize: 16),),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SquareTextField(
                width: 0.4,
                child: TextFormField(
                  enabled: !_editMode,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.text,
                  controller: _TTimeStartHour,
                  decoration: squareInputDecoration('Heure de debut', Icons.alarm)
                )
              ),
              SquareTextField(
                width: 0.4,
                child: TextFormField(
                  enabled: !_editMode,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.text,
                  controller: _TTimeStartMinute,
                  decoration: squareInputDecoration('Minute de debut', Icons.alarm)
                )
              ),
            ],
          ),
          Text('Fin', style: GoogleFonts.roboto(fontSize: 16),),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SquareTextField(
                width: 0.4,
                child: TextFormField(
                  enabled: !_editMode,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.text,
                  controller: _TTimeEndHour,
                  decoration: squareInputDecoration('Heure de Fin', Icons.alarm)
                )
              ),
              SquareTextField(
                width: 0.4,
                child: TextFormField(
                  enabled: !_editMode,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.text,
                  controller: _TTimeEndMinute,
                  decoration: squareInputDecoration('Minute de Fin', Icons.alarm)
                )
              ),
            ],
          ),
        ],
      );
    }
    else if (_triggervalue == _triggerLabel[TRIGGERS.PERIODIC]) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text('Lun'),
                  Checkbox(
                    value: _TMon,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TMon = e!;
                      });
                    }
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Mar'),
                  Checkbox(
                    value: _TTue,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TTue = e!;
                      });
                    }
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Mer'),
                  Checkbox(
                    value: _TWen,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TWen = e!;
                      });
                    }
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Jeu'),
                  Checkbox(
                    value: _TThu,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TThu = e!;
                      });
                    }
                  ),
                ]
              ),
              Column(
                children: [
                  Text('Ven'),
                  Checkbox(
                    value: _TFri,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TFri = e!;
                      });
                    }
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Sam'),
                  Checkbox(
                    value: _TSat,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TSat = e!;
                      });
                    }
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Dim'),
                  Checkbox(
                    value: _TSun,
                    onChanged: _editMode ? null : (bool? e) {
                      setState(() {
                        _TSun = e!;
                      });
                    }
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SquareTextField(
                width: 0.4,
                child: TextFormField(
                  enabled: !_editMode,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.text,
                  controller: _TTimeHour,
                  decoration: squareInputDecoration('Heure', Icons.alarm)
                )
              ),
              SquareTextField(
                width: 0.4,
                child: TextFormField(
                  enabled: !_editMode,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.text,
                  controller: _TTimeMinute,
                  decoration: squareInputDecoration('Minute', Icons.alarm)
                )
              ),
            ],
          ),
        ],
      );
    }
    else return Container();
  }

  Widget _buildActionPayload() {
    if (_actionValue == _actionLabel[ACTIONS.SAY_MESSAGE]) {
      return Column(
        children: [
          SquareTextField(
            child: TextFormField(
              enabled: !_editMode,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              keyboardType: TextInputType.text,
              controller: _ASayMessage,
              decoration: squareInputDecoration('Message', Icons.alarm)
            )
          ),
        ],
      );
    }
    else if (_actionValue == _actionLabel[ACTIONS.LIST_FORGOTTEN]) { //Ajouter multi string
      return Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            itemCount: _AListForgoten.length,
            itemBuilder: (context, index) {
              return SquareTextField(
                width: 0.7,
                child: TextFormField(
                  enabled: !_editMode,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  keyboardType: TextInputType.text,
                  controller: _AListForgoten[index],
                  decoration: squareInputDecoration('Oubli supplémentaire N°${index + 1}', Icons.remember_me)
                )
              );
            },
          ),
          _editMode ? Container() :  Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _AListForgoten.add(TextEditingController());
                  });
                },
                child: Icon(Icons.add),
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(15),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _AListForgoten.removeLast();
                  });
                },
                child: Icon(Icons.remove),
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(15),
                ),
              ),
            ],
          ),
          SizedBox(height: 32.0)
        ],
      );
    }
    else return Container();
  }

}
