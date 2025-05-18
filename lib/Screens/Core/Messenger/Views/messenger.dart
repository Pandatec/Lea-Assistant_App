//import 'dart:math' show Random;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lea_connect/Components/square_text_field.dart';
import 'package:lea_connect/Constants/style.dart';
import 'package:lea_connect/Data/Models/TextMessage.dart';
import 'package:lea_connect/Data/Repository/auth_repository.dart';
import 'package:lea_connect/Data/Repository/patient_session.dart';
import 'package:lea_connect/Screens/Core/Bar.dart';
import 'package:lea_connect/Utilities/api_client.dart';
import 'package:lea_connect/Utilities/timestamp.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class Messenger extends StatefulWidget {
  final PatientSession session;
  final String initialText;

  const Messenger(this.session, this.initialText, {Key? key}) :
    super(key: key);

  @override
  _MessengerState createState() => _MessengerState();
}

class _MessengerState extends State<Messenger> {
  PatientSession get session => widget.session;

  final _content = TextEditingController();
  final _scrollController = ScrollController();
  List<TextMessage> _history = [];
  bool _isHistoryLoaded = false;
  String _sentMsg = '';
  int lastHistoryCount = 0;
  bool _needsScroll = false;
  late WsSubscription _sub;

  @override
  initState() {
    super.initState();
    _sub = wsRepository.listen(WsSubscriptionKind.NewTextMessage, (event) {
      var n = TextMessage.fromJson(event['data']);
      setState(() {
        _history.add(n);
        _needsScroll = true;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _sub.cancel();
  }

  @override
  didUpdateWidget(Messenger w) {
    super.didUpdateWidget(w);
    _scrollToBottom();
  }

  _scrollToBottom() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeOut
    );
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    final sendMessage = (String msg) {
      // Make the keyboard disappear
      FocusManager.instance.primaryFocus?.unfocus();
      if (msg.isEmpty)
        return;
      session.createTextMessage(dateTimeSecondsSinceEpoch(DateTime.now()), msg).then((value) {
        either(context, value)((v) {
          setState(() {
            _history.add(TextMessage.fromJson(v['text_message']));
            _needsScroll = true;
          });
        }, (e) {
          _content.text = _sentMsg;
        });
      });
    };
    if (!_isHistoryLoaded) {
      _isHistoryLoaded = true;
      session.getPatientMessages().then((value) {
        eitherThen(context, value)((v) {
          setState(() {
            for (final msg in v['text_messages'])
              _history.add(TextMessage.fromJson(msg));
            sendMessage(widget.initialText);
            _needsScroll = true;
          });
        });
      });
    }
    if (_needsScroll) {
      WidgetsBinding.instance?.addPostFrameCallback((_) => _scrollToBottom());
      _needsScroll = false;
    }
    showOptions() async {
      showDialog(
          context: context,
          builder: (context) {
            var setValue = (String? value) async {
              if (value == null)
                return;
              _content.text = value;
              Navigator.pop(context);
            };
            var genTile = (String text) {
              return ListTile(
                  title: Text(text),
                  leading: Radio<String>(
                      value: text,
                      groupValue: _content.text,
                      onChanged: setValue));
            };
            return AlertDialog(
              title: Text('Suggestions'),
              content: Column(children: <Widget>[
                genTile('Bonjour !'),
                genTile('Je pense à toi <3'),
                genTile('Gros bisous !'),
                genTile('Comment vas-tu ?'),
                genTile("Que fais-tu aujourd'hui ?"),
                genTile("Que penses-tu de Léa ?"),
                genTile("Tu as beaucoup utilisé Léa aujourd'hui !"),
                genTile("Tu as un rendez-vous chez le coiffeur demain à 14h."),
              ]));
          }
      );
    }
    return Scaffold(
        appBar: Bar(session, Icon(Icons.message), extraActions: [
          IconButton(icon: Icon(Icons.more_horiz_outlined),
            color: kAccent,
            onPressed: () {
              showOptions();
            },
          )
        ], isInMessenger: true),
        body: Container(
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Hero(
                  tag: 'logo',
                  child: Container(
                      height: 50,
                      color: Colors.white,
                      child: ClipOval(
                        child: Image.asset(
                          "assets/logos/primary_no_text.png",
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                        ),
                      ))),
              Expanded(
                child: Container(
                  color: Color(0xFFf6F6F6),
                  child: ListView.separated(
                    controller: _scrollController,
                    separatorBuilder: (context, index) => SizedBox(height: 0),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final msg = _history[index];
                      return Container(
                        padding: EdgeInsets.only(left: msg.is_from_patient ? 0 : 128, right: msg.is_from_patient ? 128 : 0),
                        child:
                          Card(
                            elevation: 3,
                            margin: EdgeInsets.all(12),
                            child: ListTile(
                              minVerticalPadding: 12,
                              title: Text(
                                timeago.format(dateTimeFromSecondsSinceEpoch(msg.datetime), locale: translations.locale),
                                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)
                              ),
                              subtitle: Text(msg.msg),
                              onTap: () {
                                if (msg.is_from_patient)
                                  return;
                                session.playTextMessage(msg.id).then((value) {
                                  eitherThen(context, value)((v) {
                                    setState(() {
                                      _history[index] = TextMessage.fromJson(v['text_message']);
                                    });
                                  });
                                });
                              },
                              trailing: msg.is_from_patient ?
                                null :
                                msg.play_count == 0 ?
                                  Icon(Icons.error, color: Colors.red) :
                                  Icon(Icons.check, color: Colors.green)
                            )
                          )
                      );
                    }
                  )
                )
              ),
              Hero(
                  tag: 'message_input',
                  child: Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SquareTextField(
                        child: TextField(
                          controller: _content,
                          onTap: () => Timer(Duration(milliseconds: 200), _scrollToBottom),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: translations.messenger.hint,
                            hintStyle: TextStyle(color: Colors.grey),
                            contentPadding: EdgeInsets.all(12.0),
                          )
                        ),
                        width: 0.70,
                      ),
                      SizedBox(width: 10),
                      Container(
                        height: 48,
                        child: ElevatedButton(
                          child: Icon(Icons.send),
                          onPressed: () {
                            _sentMsg = _content.text;
                            _content.text = '';
                            sendMessage(_sentMsg);
                          }
                        )
                      )
                    ]
                  )
                )
              ),
              SizedBox(height: 28)
            ]
          )
        )
      );
  }
}
