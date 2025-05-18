import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_map_dragmarker/dragmarker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lea_connect/Components/square_text_field.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/Bar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class Location extends StatefulWidget {
  final PatientSession session;

  Location(this.session);

  @override
  _LocationState createState() => _LocationState();
}

class _LocationState extends State<Location> {
  PatientSession get session => widget.session;

  @override
  initState() {
    super.initState();
    wsRepository.enable(session.patient.id, PatientEventClass.Location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Bar(session, Icon(Icons.location_pin)),
      body: LocationPosition(session)
    );
  }

  @override
  void dispose() {
    super.dispose();
    wsRepository.disable(PatientEventClass.Location);
  }
}

class LocationPosition extends StatefulWidget {
  final PatientSession session;

  LocationPosition(this.session);

  @override
  _LocationPositionState createState() => _LocationPositionState();
}

abstract class Zone {
  String id;
  String name;
  int color;  // pad8r8g8b8
  String safety;

  Zone(String id, String name, int color, String safety) :
    id = id,
    name = name,
    color = color,
    safety = safety;

  String _getType();
  void _jsonWrite(Map<String, dynamic> obj);
  List<LayerOptions> _toMapLayers();
  LatLng _getCenter();
  bool isInside(LatLng p);
  List<LatLng> getControlPoints();
  void moveControl(int ndx, LatLng p);

  static Zone fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'polygon')
      return PolygonZone(json['id'], json['name'], json['color'], json['safety'], (json['points'] as List<dynamic>).map((v) => _jsonToLatLng(v)).toList());
    else if (json['type'] == 'circle')
      return CircleZone(json['id'], json['name'], json['color'], json['safety'], _jsonToLatLng(json['center']), json['radius'].toDouble());
    else
      throw Exception('Unknown zone type ${json['type']}');
  }

  Map<String, dynamic> toJson() {
    final res = Map<String, dynamic>();
    res['id'] = id;
    res["type"] = _getType();
    res["name"] = name;
    res["color"] = color;
    res["safety"] = safety;
    _jsonWrite(res);
    return res;
  }

  static dynamic _latLngToJson(LatLng p) {
    return <String, double>{
      'lat': p.latitude,
      'lng': p.longitude
    };
  }

  static LatLng _jsonToLatLng(Map<String, dynamic> json) {
    return LatLng(json['lat'], json['lng']);
  }

  static mp.LatLng _convMpLatLng(LatLng p) {
    return mp.LatLng(p.latitude, p.longitude);
  }

  Color _getCanonicalColor({int alpha = 0x80}) {
    return Color((alpha << 24) + color);
  }

  Color _thicken(Color color) {
    return Color.fromARGB(255, color.red, color.green, color.blue);
  }

  List<LayerOptions> toMapLayers() {
    return _toMapLayers() + [
      MarkerLayerOptions(markers: [
        Marker(
          point: _getCenter(),
          width: 192,
          builder: (ctx) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              safety == 'home' ? 
                Text("⌂", style: TextStyle(color: Color.fromARGB(255, 16, 159, 190))) :
                Text("${safety != "danger" ? "✓" : "✘"}", style: TextStyle(color: Color(safety != "danger" ? 0xFF00BF00 : 0xFFFF0000))),
              Text("${name}",
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold
                )
              )
            ])
          )
      ])
    ];
  }
}

class PolygonZone extends Zone {
  final List<LatLng> _points;

  PolygonZone(String id, String name, int color, String isSafe, List<LatLng> points) :
    _points = points,
    super(id, name, color, isSafe)
  {
  }

  @override String _getType() {
    return "polygon";
  }

  @override void _jsonWrite(Map<String, dynamic> obj) {
    obj["points"] = _points.map(Zone._latLngToJson).toList();
  }

  @override List<LayerOptions> _toMapLayers() {
    return [
      PolygonLayerOptions(polygons: [
        Polygon(
          points: _points,
          color: _getCanonicalColor(alpha: 96),
          borderStrokeWidth: 2.0,
          borderColor: _thicken(_getCanonicalColor()),
          isFilled: true,

        )
      ])
    ];
  }

  @override LatLng _getCenter() {
    double lat = 0, lng = 0;
    for (final p in _points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    final c = _points.length.toDouble();
    return LatLng(lat / c, lng / c);
  }

  @override
  bool isInside(LatLng p) {
    return mp.PolygonUtil.containsLocation(Zone._convMpLatLng(p), _points.map(Zone._convMpLatLng).toList(), true);
  }

  @override
  List<LatLng> getControlPoints() {
    return _points;
  }

  @override
  void moveControl(int ndx, LatLng p) {
    _points[ndx] = p;
  }
}

class CircleZone extends Zone {
  LatLng center;
  double radius;

  CircleZone(String id, String name, int color, String safety, LatLng center, double radius) :
    center = center,
    radius = radius,
    super(id, name, color, safety);

  @override String _getType() {
    return "circle";
  }

  @override void _jsonWrite(Map<String, dynamic> obj) {
    obj["center"] = Zone._latLngToJson(center);
    obj["radius"] = radius;
  }

  @override List<LayerOptions> _toMapLayers() {
    return [
      CircleLayerOptions(circles: [
        CircleMarker(
          point: center,
          radius: radius,
          useRadiusInMeter: true,
          color: _getCanonicalColor(alpha: 96),
          borderStrokeWidth: 2.0,
          borderColor: _thicken(_getCanonicalColor())
        )
      ])
    ];
  }

  @override LatLng _getCenter() {
    return center;
  }

  @override
  bool isInside(LatLng p) {
    return mp.SphericalUtil.computeLength([
      center,
      p
    ].map(Zone._convMpLatLng).toList()) < radius;
  }

  @override
  List<LatLng> getControlPoints() {
    return [
      center,
      Distance().offset(center, radius, 45)
    ];
  }

  @override
  void moveControl(int ndx, LatLng p) {
    if (ndx == 0)
      center = p;
    else
      radius = mp.SphericalUtil.computeLength([center, p].map(Zone._convMpLatLng).toList()).toDouble();
  }
}

class _LocationPositionState extends State<LocationPosition> {
  PatientSession get session => widget.session;

  static double _baseZoom = 16.0;
  static double _newZoneOff = 0.0005;

  bool _showZones = true;
  double _lat = 0.0;
  double _lng = 0.0;
  String _diag = "";
  bool _zonesCoherent = false;
  List<Zone> _zones = [];
  bool _isAlreadyHome = false;
  Zone? _selecZone;
  late WsSubscription _sub;
  final _controller = MapController();
  final _zoneNameController = TextEditingController();

  void _selectZone(Zone? z) {
    _selecZone = z;
    if (z != null) {
      _zoneNameController.text = z.name;
    }
  }

  @override
  void initState() {
    super.initState();
    _sub = wsRepository.listen(WsSubscriptionKind.Location, (event) {
      var t = event['type'];
      if (t == 'locationPosition') {
        var d = event['data'];
        setState(() {
          _lat = d['lat'];
          _lng = d['lng'];
          _diag = "";
        });
      } else if (t == 'locationDiag') {
        setState(() {
          _diag = event['data'];
        });
      }
    });
    _controller.mapEventStream.listen((event) {
      if (event is MapEventTap && _showZones) {
        final e = event;
        Zone? nz;
        for (final z in _zones)
          if (z.isInside(e.tapPosition)) {
            if (_selecZone == z)
              nz = null;
            else
              nz = z;
            break;
          }
        if (nz != _selecZone)
          setState(() {
            if (nz == null) {
              {
                final z = _selecZone!;
                session.patchPatientZone(z).then((value) {
                  eitherThen(context, value)((v) {
                    z.id = v["zone_id"];
                  });
                });
              }
            }
            _selectZone(nz);
          });
      }
    });
    _zoneNameController.addListener(() {
      if (_selecZone == null)
        return;
      if (_zoneNameController.text.length > 0)
        _selecZone!.name = _zoneNameController.text;
    });
    session.getPatientZones().then((value) {
      eitherThen(context, value)((v) {
        setState(() {
          _zones = (v['zones'] as List<dynamic>).map((v) => Zone.fromJson(v)).toList();
          _zonesCoherent = true;
          inspect(_zones);
        });
      });
    });

    session.checkHome().then((value) {
      eitherThen(context, value)((v) {
        setState(() {
          _isAlreadyHome = true;
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();
  }

  List<LayerOptions> _zoneLayers() {
    final List<LayerOptions> zones = (_showZones ? _zones.fold(<LayerOptions>[], (acc, e) {
        acc.addAll(e.toMapLayers());
        return acc;
      }) : []);
    return zones;
  }

  List<LayerOptions> _selecZoneLayers() {
    int i = 0;
    final sz = _selecZone;
    final List<LayerOptions> selec = (sz != null ?
      [DragMarkerPluginOptions(markers:
        sz.getControlPoints().map((e) {
          int idx = i++;
          return DragMarker(
            point: e,
            width: 80.0,
            height: 80.0,
            builder: (ctx) => Container(child: Icon(Icons.circle, size: 20, color: sz._getCanonicalColor(alpha: 0xC0))),
            onDragUpdate: (details, p) {
              setState(() {
                sz.moveControl(idx, p);
              });
            },
          );
        }).toList()
      )] : []);
    return selec;
  }

  void _showColorPicker(BuildContext ctx) {
    final translations = AppLocalizations.of(context);
    showDialog(
      context: ctx,
      builder: (ctx) => AlertDialog(
        title: Text(translations.location.zone.color.pick),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: Color(_selecZone!.color),
            onColorChanged: (c) {
              setState(() {
                _selecZone!.color = c.value & 0xFFFFFF;
              });
              Navigator.of(ctx).pop();
            }
          )
        )
      ),
    );
  }

  Widget buildCreateZone(BuildContext ctx) {
    final translations = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 24.0, right: 17.0),
      child: SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.remove,
      buttonSize: 60,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      children: [SpeedDialChild(
                    child: Icon(
                      Icons.crop_square,
                      size: 32,
                      color: Colors.white
                    ),
                    onTap: () => {
                      setState(() {
                        final z = PolygonZone('', translations.location.zone.created, Colors.blue.value, 'safe', [
                          LatLng(_lat - _newZoneOff, _lng - _newZoneOff),
                          LatLng(_lat + _newZoneOff, _lng - _newZoneOff),
                          LatLng(_lat + _newZoneOff, _lng + _newZoneOff),
                          LatLng(_lat - _newZoneOff, _lng + _newZoneOff)
                        ]);
                        _zones.add(z);
                        _selectZone(z);
                        {
                          final z = _selecZone!;
                          session.patchPatientZone(z).then((value) {
                            eitherThen(context, value)((v) {
                              z.id = v["zone_id"];
                            });
                          });
                        }
                      })
                    }
                  ),
                SpeedDialChild(
                    child: Icon(
                      Icons.circle_outlined,
                      size: 32,
                      color: Colors.white
                    ),
                    onTap: () => {
                      setState(() {
                        final z = CircleZone('', translations.location.zone.created, Colors.green.value, 'safe',
                          LatLng(_lat + _newZoneOff, _lng + _newZoneOff),
                          50.0
                        );
                        _zones.add(z);
                        _selectZone(z);
                        {
                          final z = _selecZone!;
                          session.patchPatientZone(z).then((value) {
                            eitherThen(context, value)((v) {
                              z.id = v["zone_id"];
                            });
                          });
                        }
                      })
                    }
                  ),
                ]
    ));
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);

    if ((_lat == 0.0 && _lng == 0.0) || !_zonesCoherent)
      return Align(
        alignment: Alignment(0.0, 0.0),
        child: Text(
          _diag == "" ? translations.location.loading : "${translations.location.waiting_patient}: \n${(translations.location.diag as dynamic)[_diag]}",
          textAlign: TextAlign.justify
        )
      );
    //log("LAT: ${_lat}\nLNG: ${_lng}${_diag == "" ? "" : "\nDIAG: ${_diag}"}");
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        center: LatLng(_lat, _lng),
        zoom: _baseZoom,
        interactiveFlags: InteractiveFlag.all & (~InteractiveFlag.rotate),
        allowPanningOnScrollingParent: false,
        plugins: [
          DragMarkerPlugin()
        ]
      ),
      layers: <LayerOptions>[
        TileLayerOptions(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
      ] + _zoneLayers() + <LayerOptions>[
        MarkerLayerOptions(
          markers: [
            Marker(
              width: 30.0,
              height: 30.0,
              point: LatLng(_lat, _lng),
              builder: (ctx) =>
              Container(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Icon(Icons.location_pin,
                      size: 48.0,
                      color: _diag == "" ? kAccent : Colors.grey
                    )
                  ] + (_diag == "" ? [] : [
                    Positioned(
                      bottom: 32,
                      left: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          left: 4.0,
                          top: 4.0,
                          right: 4.0,
                          bottom: 4.0,
                        ),
                        color: Colors.black.withOpacity(0.45),
                        child: Text(
                          (translations.location.diag as dynamic)[_diag],
                          style: TextStyle(
                            color: Colors.white
                          )
                        )
                      )
                    )
                  ])
                )
              )
            )
          ],
        )
      ] + _selecZoneLayers(),
      nonRotatedChildren: <Widget>[
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(bottom: 16.0 + 64.0,),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[]
                + (_selecZone == null ? [
                Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: RawMaterialButton(
                    fillColor: _showZones ? kAccent : Colors.grey,
                    shape: CircleBorder(),
                    child: Icon(
                      Icons.remove_red_eye,
                      size: 32,
                      color: Colors.white
                    ),
                    padding: EdgeInsets.all(8.0),
                    onPressed: () => {
                      setState(() => {
                        _showZones = !_showZones
                      })
                    }
                  ),
                )] : []) + [
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 16.0),
                  child: RawMaterialButton(
                    fillColor: kAccent,
                    shape: CircleBorder(),
                    child: Icon(
                      Icons.my_location_outlined,
                      size: 32,
                      color: Colors.white
                    ),
                    padding: EdgeInsets.all(8.0),
                    onPressed: () => {
                      setState(() => {
                        _controller.move(LatLng(_lat, _lng), _baseZoom)
                      })
                    }
                  )
                )
              ]
            )
          )
        )
      ] + (_selecZone != null ? [
        Align(
          alignment: Alignment.topCenter,
          child: Column(children: [
              SquareTextField(
                child: TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.text,
                    controller: _zoneNameController,
                    decoration: squareInputDecoration(translations.location.zone.name, Icons.label_important_outline_sharp)
                )
              ),
              SquareTextField(
                child:
                  Row(children: [
                    /* Checkbox(
                      value: _selecZone!.isSafe,
                      onChanged: (value) {
                        setState(() {
                          _selecZone!.isSafe = !_selecZone!.isSafe;
                        });
                    }), */
                    DropdownButton(
                      value: _selecZone!.safety,
                      items: (_isAlreadyHome && _selecZone!.safety != 'home' ? [['safe', 'Sûre'], ['danger', 'Dangereuse']] : [['home', 'Domicile'], ['danger', 'Dangereuse'], ['safe', 'Sûre']]).map((List<String> items) {
                        return DropdownMenuItem(
                          value: items[0],
                          child: Text(items[1]),
                        );
                      }).toList(),
                      onChanged: (String ?value) {
                        setState(() {
                          _selecZone!.safety = value!;
                        });
                      }
                    ),
                    //Text(translations.location.zone.isSafe),
                    Padding(
                      padding: EdgeInsets.only(left: 24.0),
                      child: RawMaterialButton(
                        constraints: BoxConstraints(minWidth: 48.0, minHeight: 36.0),
                        fillColor: Color(_selecZone!.color | 0xFF000000),
                        shape: CircleBorder(),
                        child: Icon(
                          Icons.circle,
                          size: 16,
                          color: Color(_selecZone!.color | 0xFF000000)
                        ),
                        padding: EdgeInsets.only(
                          left: 8.0,
                          top: 8.0,
                          right: 8.0,
                          bottom: 8.0,
                        ),
                        onPressed: () => {
                          _showColorPicker(context)
                        }
                      )
                    ),
                    Text(translations.location.zone.color.name),
                    Padding(
                      padding: EdgeInsets.only(left: 24.0),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _zones.remove(_selecZone!);
                            session.deletePatientZone(_selecZone!);
                            _selecZone = null;
                          });
                        },
                        child: Text(translations.location.zone.delete,
                          style: TextStyle(
                            color: Colors.red
                          )
                        )
                      )
                    )
                  ])
              )
            ]
          )
        )
      ] : []) + [buildCreateZone(context)],
    );
  }
}
