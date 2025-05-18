import 'package:flutter/material.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Data/Repository/user_session.dart';
import 'package:lea_connect/Data/Models/Notification.dart';
import 'package:lea_connect/Screens/Core/Messenger/Views/messenger.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/Utilities/timestamp.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class Bar extends AppBar {
  Bar(UserSession session, Icon icon, {List<Widget> extraActions = const [], isInMessenger = false}) :
    super(
      backgroundColor: kPrimaryColor,
      centerTitle: true,
      leading: Row(children: extraActions),
      actions: (<Widget>[]) + [
        _BarNotifs(session)]
    );
}

class _BarNotifs extends StatefulWidget {
  final UserSession session;

  _BarNotifs(this.session);

  @override
  _BarNotifsState createState() => _BarNotifsState();
}

class _BarNotifsState extends State<_BarNotifs> {
  UserSession get session => widget.session;

  int _count = 0;
  WsSubscription? sub;

  @override
  void dispose() {
    super.dispose();
    sub?.cancel();
  }

  void _setCount(int newValue) {
    if (_count != newValue)
      setState(() {
        _count = newValue;
      });
  }

  void _updateUnread() {
    session.getUnreadNotificationCount().then((value) {
      eitherThen(context, value)((v) {
        _setCount(v['count']);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _updateUnread();

    if (sub == null)
      sub = wsRepository.listen(WsSubscriptionKind.NewNotificationCount, (event) {
        _setCount(event['data']['count']);
      });

    return new Stack(
      children: <Widget>[
        new IconButton(
          color: kAccent,
          icon: Icon(Icons.notifications_outlined, color: kAccent,),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => NotificationDialog(session)
            );
          }),
        _count > 0
            ? new Positioned(
                right: 11,
                top: 11,
                child: new Container(
                  padding: EdgeInsets.all(2),
                  decoration: new BoxDecoration(
                    color: kAlert,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    '${_count}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : new Container()
      ]
    );
  }
}

class NotificationDialog extends StatefulWidget {
  final UserSession session;

  NotificationDialog(this.session);

  @override
  _NotificationDialogState createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  UserSession get session => widget.session;

  int _page = 0;
  bool _isLoading = false;
  ScrollController _scController = ScrollController();
  List<Notif> notifs = [];

  void initState() {
    super.initState();

    _isLoading = true;
    session.getNotifications(_page).then((value) {
      _isLoading = false;
      eitherThen(context, value)((v) {
        _page++;
        setState(() {
          for (var nr in v['notifs'] as List<dynamic>) {
            var n = Notif.fromJson(nr);
            notifs.add(n);
          }
        });
      });
    });
  }

  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(translations.settings.notifications),
      content: Container(
        width: double.maxFinite,
        height: 450,
        child: NotificationListener(
          child: ListView.separated(
            controller: _scController,
            separatorBuilder: (BuildContext context, int index) => const Divider(),
            itemCount: notifs.length + 1,
            itemBuilder: (context, index) {
              if (index == notifs.length)
                return Icon(Icons.pending, color: Colors.black12);
              else
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                        timeago.format(dateTimeFromSecondsSinceEpoch(notifs[index].created_at), locale: translations.locale),
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)
                    ),
                    Text(notifs[index].title, style: TextStyle(fontWeight: notifs[index].is_read ? FontWeight.normal : FontWeight.bold))
                  ] + (notifs[index].message.length > 0 ? [Text(notifs[index].message, style: TextStyle(fontSize: 14))] : [])
                );
            }
          ),
          onNotification: (t) {
            if (t is ScrollEndNotification && !_isLoading && (_scController.position.pixels == _scController.position.maxScrollExtent)) {
              _isLoading = true;
              session.getNotifications(_page).then((value) {
                _isLoading = false;
                eitherThen(context, value)((v) {
                  _page++;
                  setState(() {
                    for (var nr in v['notifs'] as List<dynamic>) {
                      var n = Notif.fromJson(nr);
                      notifs.add(n);
                    }
                  });
                });
              });
            }
            return true;
          },
        )
      )
    );
  }
}