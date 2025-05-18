import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:lea_connect/Constants/home.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:latlong2/latlong.dart';

import '../../../Data/Repository/patient_session.dart';
import '../cubit/nav_core_cubit.dart';

class MiniMap extends StatefulWidget {
  final PatientSession session;
  const MiniMap(this.session, {Key? key}) : super(key: key);

  @override
  State<MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<MiniMap> {
  PatientSession get session => widget.session;

  final _controller = MapController();
  bool initialized = false;

  late WsSubscription _subLocation;
  double _lat = 0;
  double _lng = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    wsRepository.enable(session.patient.id, PatientEventClass.Location);
    _subLocation = wsRepository.listen(WsSubscriptionKind.Location, (event) {
      var t = event['type'];
      if (t == 'locationPosition') {
        var d = event['data'];
        setState(() {
          _lat = d['lat'];
          _lng = d['lng'];
          if (initialized)
            _controller.move(LatLng(_lat, _lng), 16.0);
          initialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _subLocation.cancel();
    wsRepository.disable(PatientEventClass.Location);
  }
  Widget _buildMiniMap() {
      Size size = MediaQuery.of(context).size;
      if ((_lat == 0.0 || _lng == 0.0))
        return Align(
            alignment: Alignment(0.0, 0.0),
            child:
                Text("Récupération des données", textAlign: TextAlign.justify));
      return Container(
          height: size.height * 0.3,
          child: Padding(
              padding: EdgeInsets.all(15.0),
              child: FlutterMap(
              mapController: _controller,
              layers: [
                TileLayerOptions(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayerOptions(
                  markers: [
                    Marker(
                        width: 30.0,
                        height: 30.0,
                        point: LatLng(_lat, _lng),
                        builder: (ctx) => Container(
                                child: Stack(
                                    clipBehavior: Clip.none,
                                    children: <Widget>[
                                  Icon(Icons.location_pin,
                                      size: 48.0, color: kAccent)
                                ])))
                  ],
                )
              ],
              options: MapOptions(
                onLongPress: ((tapPosition, point) {
                  homeKey.currentState!.updateIndex(Pages.map);
                }),
                center: LatLng(_lat, _lng),
                zoom: 16.0,
              )
            ),
          ),
      );
    }
  
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 30.0), child: Card(elevation: 15.0, child: _buildMiniMap(),),);
  }
}