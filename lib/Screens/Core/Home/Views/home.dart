import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:lea_connect/Components/custom_background.dart';
import 'package:lea_connect/Constants/home.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Models/Notification.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/Bar.dart';
import 'package:lea_connect/Screens/Core/Home/Widgets/patient_status_card.dart';
import 'package:lea_connect/Screens/Core/cubit/nav_core_cubit.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/main.dart';
import 'package:onboarding/onboarding.dart';
import 'package:latlong2/latlong.dart';

import '../../../../Components/charts/chart_holder.dart';
import '../../patientDashboard/patient_dashboard.dart';


class HomeScreen extends StatefulWidget {
  final PatientSession session;

  const HomeScreen(this.session, {Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PatientSession get session => widget.session;
  late bool patientIsConnected;
  double? lastPatientBatteryLevel;
  late double? patientBatteryLevel;
  late WsSubscription _sub;
  late WsSubscription _subLocation;
  late WsSubscription _subNotifSnack;

  final _controller = MapController();

  double _lat = 50.280228;
  double _lng = 3.9674;

  
  @override
  void initState() {
    super.initState();
    patientIsConnected = session.patient.isConnected;
    patientBatteryLevel = session.patient.batteryLevel;
    lastPatientBatteryLevel = patientBatteryLevel;
    wsRepository.enable(session.patient.id, PatientEventClass.BatteryLevel);
    wsRepository.enable(session.patient.id, PatientEventClass.Location);

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

    _subLocation = wsRepository.listen(WsSubscriptionKind.Location, (event) {
      var t = event['type'];
      if (t == 'locationPosition') {
        var d = event['data'];
        setState(() {
          _lat = d['lat'];
          _lng = d['lng'];
          //_controller.move(LatLng(_lat, _lng), 16.0);
        });
      }
    });

    _subNotifSnack =
        wsRepository.listen(WsSubscriptionKind.NewNotification, (event) {
      var n = Notif.fromJson(event['data']);
      if (!App.of(navigatorKey.currentContext!).isDND())
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(SnackBar(
            content: Container(
                padding: EdgeInsets.only(bottom: 24.0),
                child: Text(
                    "${n.title}${n.message != '' ? ": ${n.message}" : ''}"))));
      session.getUnreadNotificationCount().then((value) {
        eitherThen(context, value)((v) {
          final int count = v['count'];
          wsRepository.emit(WsSubscriptionKind.NewNotificationCount, {
            "data": {"count": count}
          });
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();
    _subLocation.cancel();
    _subNotifSnack.cancel();
    wsRepository.disable(PatientEventClass.BatteryLevel);
    wsRepository.disable(PatientEventClass.Location);
  }

  late int index = 0;

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    Size size = MediaQuery.of(context).size;
    final List<Image> imageLists = [
      Image.asset(translations.helper.home_img),
      Image.asset(translations.helper.calendar_img),
      Image.asset(translations.helper.location_img),
      Image.asset(translations.helper.patient_img),
      Image.asset(translations.helper.profile_img)
    ];

    final onboardingPagesList = [
      PageModel(
          widget: Container(
        height: MediaQuery.of(context).size.width / 2,
        width: MediaQuery.of(context).size.width / 1.4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          image:
              DecorationImage(image: imageLists[0].image, fit: BoxFit.contain),
        ),
      )),
      PageModel(
          widget: Container(
        height: MediaQuery.of(context).size.width / 2,
        width: MediaQuery.of(context).size.width / 1.4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          image:
              DecorationImage(image: imageLists[1].image, fit: BoxFit.contain),
        ),
      )),
      PageModel(
          widget: Container(
        height: MediaQuery.of(context).size.width / 2,
        width: MediaQuery.of(context).size.width / 1.4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          image:
              DecorationImage(image: imageLists[2].image, fit: BoxFit.contain),
        ),
      ))
    ];

    Widget _buildLogo() {
      return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Hero(
              tag: 'logo',
              child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 100),
                  child: ClipOval(
                      child: Image.asset(
                    "assets/logos/primary_no_text.png",
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                  )))));
    }

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

    Widget _buildMiniMap() {
      if ((_lat == 0.0 || _lng == 0.0))
        return Align(
            alignment: Alignment(0.0, 0.0),
            child:
                Text("Récupération des données", textAlign: TextAlign.justify));
      return Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          height: size.height * 0.3,
          child: Card(
            elevation: 20.0,
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
                onTap: ((tapPosition, point) {
                  homeKey.currentState!.updateIndex(Pages.map);
                }),
                center: LatLng(_lat, _lng),
                zoom: 16.0,
              )
            ),
            ),
          )
      );
    }

    return Scaffold(
        appBar: Bar(
          session,
          Icon(
            Icons.home_outlined,
            color: kAccent,
          ),
          extraActions: [
            IconButton(
                icon: Icon(
                  Icons.help_outline,
                  color: kAccent,
                ),
                onPressed: () => {
                      showDialog(
                          context: context,
                          builder: (context) => Container(
                                width: size.width,
                                height: size.height,
                                child: Onboarding(
                                  pages: onboardingPagesList,
                                  onPageChange: (int pageIndex) {
                                    index = pageIndex;
                                  },
                                  startPageIndex: 0,
                                  footerBuilder: (context, dragDistance,
                                      pagesLength, setIndex) {
                                    return DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: background,
                                        border: Border.all(
                                          width: 0.0,
                                          color: background,
                                        ),
                                      ),
                                      child: ColoredBox(
                                        color: background,
                                        child: Padding(
                                          padding: const EdgeInsets.all(45.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              CustomIndicator(
                                                netDragPercent: dragDistance,
                                                pagesLength: pagesLength,
                                                indicator: Indicator(
                                                  indicatorDesign:
                                                      IndicatorDesign.line(
                                                    lineDesign: LineDesign(
                                                      lineType: DesignType
                                                          .line_uniform,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )),
                    })
          ],
        ),
        body: Stack(
          children: [
            CustomBackground(),
            /* Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                  width: size.width,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLogo(),
                        GestureDetector(
                          child: _buildPatientCard(),
                          onTap: () {
                            homeKey.currentState!.updateIndex(Pages.patient);
                          },
                        ),
/*                         _buildSendMessage(),
                        _buildEvents(), */
                        SizedBox(
                          height: 20,
                        ),
                        _buildMiniMap(),
                        SizedBox(
                          height: 40,
                        ),
                      ],
                    ),
                  )),
            ), */
          ],
        ));
  }
}
