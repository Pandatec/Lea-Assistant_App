import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lea_connect/Components/circular.dart';
import 'package:lea_connect/Constants/home.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Screens/Core/Calendar/Views/calendar_view.dart';
import 'package:lea_connect/Screens/Core/Home/Views/home.dart';
import 'package:lea_connect/Screens/Core/Location/Views/location.dart';
import 'package:lea_connect/Screens/Core/Messenger/Views/messenger.dart';
import 'package:lea_connect/Screens/Core/Patient/Views/patient_list.dart';
import 'package:lea_connect/Screens/Core/Profil/Views/profil_screen.dart';
import 'package:lea_connect/Screens/Core/cubit/nav_core_cubit.dart';
import 'package:lea_connect/Screens/Core/patientDashboard/patient_dashboard_view.dart';
import 'package:lea_connect/Screens/auth/cubit/auth_cubit.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';

class CoreProvider extends StatelessWidget {
  // FAIR WARNING: this is up-to-date only at login, see details in CoreView
  final UserSession session;

  const CoreProvider(this.session, {Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        var core = NavCoreCubit(
          session,
          authenticateCubit: context.read<AuthenticateCubit>()
        );
        core.loadUser(context);
        return core;
      },
      child: CoreView(session),
    );
  }
}

class CoreView extends StatelessWidget {
  // FAIR WARNING: only the token part is relevant, user to use should be in state
  final UserSession session;

  const CoreView(this.session, {Key? key}) :
    super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavCoreCubit, NavCoreState>(
      bloc: BlocProvider.of<NavCoreCubit>(context),
      builder: (context, state) {
        if (state is NavCoreLoading)
          return LoadingScreen();
        else if (state is NavCoreLoadedNoPatient)
          return PatientList(UserSession(session.token, state.user),
              patients: state.user.patients,
              core: BlocProvider.of<NavCoreCubit>(context));
        else if (state is NavCoreLoadedPatient)
          return CoreNavigator(
            PatientSession(UserSession(session.token, state.user), state.patient),
            key: homeKey, initialPage: state.initialPage);
        else
          throw new Exception("CoreView: Unknown NavCoreState: ${state.toString()}");
      });
  }
}

class CoreNavigator extends StatefulWidget {
  final PatientSession session;
  final Pages initialPage;

  const CoreNavigator(this.session, {Key? key, required this.initialPage}) :
    super(key: key);

  @override
  CoreNavigatorState createState() => CoreNavigatorState();
}

class CoreNavigatorState extends State<CoreNavigator> {
  PatientSession get session => widget.session;

  late PersistentTabController _controller;
  String _initialText = "";

  List<Widget> _buildScreens() {
    return [
      ProfilScreen(session),
      Messenger(session, _initialText),
      PatientDashboardProvider(session),
      CalendarProvider(session),
      Location(session),
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: widget.initialPage.index);
  }

  updateIndex(Pages page) {
    _controller.index = page.index;
  }

  updateInitialText(String txt) {
    setState(() {
      _initialText = txt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);

    List<PersistentBottomNavBarItem> _navBarsItems() {
      return [
        PersistentBottomNavBarItem(
          icon: Icon(
            Icons.person_outline,
            size: 24,
          ),
          title: (translations.nav.profile),
          textStyle: TextStyle(fontSize: 11),
          activeColorPrimary: kAccent,
          inactiveColorPrimary: kInactive,
        ),
        PersistentBottomNavBarItem(
          icon: Icon(
            Icons.messenger_outline_outlined,
            size: 24,
          ),
          title: "Messagerie",
          textStyle: TextStyle(fontSize: 11),
          activeColorPrimary: kAccent,
          inactiveColorPrimary: kInactive,
        ),
        PersistentBottomNavBarItem(
          icon: Icon(
            Icons.home_outlined,
            color: Colors.white,
            size: 40,
          ),
          textStyle: TextStyle(fontSize: 15),
          activeColorPrimary: kAccent,
          inactiveColorPrimary: kInactive,
        ),
        PersistentBottomNavBarItem(
          icon: Icon(
            Icons.calendar_today_outlined,
            size: 24,
          ),
          title: (translations.nav.calendar),
          textStyle: TextStyle(fontSize: 11),
          activeColorPrimary: kAccent,
          inactiveColorPrimary: kInactive,
        ),
        PersistentBottomNavBarItem(
          icon: Icon(
            Icons.map_outlined,
            size: 24,
          ),
          title: (translations.nav.location),
          textStyle: TextStyle(fontSize: 11),
          activeColorPrimary: kAccent,
          inactiveColorPrimary: kInactive,
        ),
      ];
    }

    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineInSafeArea: true,
      backgroundColor: Colors.white, // Default is Colors.white.
      handleAndroidBackButtonPress: true, // Default is true.
      resizeToAvoidBottomInset:
          true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
      stateManagement: true, // Default is true.
      hideNavigationBarWhenKeyboardShows:
          true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(10.0),
        colorBehindNavBar: Colors.white,
      ),
      popAllScreensOnTapOfSelectedTab: true,
      popActionScreens: PopActionScreensType.all,
      itemAnimationProperties: ItemAnimationProperties(
        // Navigation Bar's items animation properties.
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: ScreenTransitionAnimation(
        // Screen transition animation on change of selected tab.
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle:
          NavBarStyle.style15, // Choose the nav bar style with this property.
    );
  }
}
