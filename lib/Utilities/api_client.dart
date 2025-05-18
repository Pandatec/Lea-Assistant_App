import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:lea_connect/Constants/url.dart';
import 'package:lea_connect/l10n/localizations.dart';
import 'package:lea_connect/main.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mutex/mutex.dart';
import 'package:either_dart/either.dart';

class ErrorDesc {
  final int code;
  final String msg;

  ErrorDesc(this.code, this.msg);
}

typedef _Left = ErrorDesc;
typedef _Right = Map<String, dynamic>;
typedef APIResponse = Either<_Left, _Right>;

void _showErrorIfFailed(BuildContext? ctx, APIResponse v) {
  if (ctx == null)
    return;
  if (v.isLeft)
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content:
        Container(
          padding: EdgeInsets.only(bottom: 24.0),
          child: Text(translateErrorMessage(ctx, v.left.msg))
        )
      )
    );
}

void Function(Function(_Right v)) eitherThen(BuildContext? ctx, APIResponse v) {
  _showErrorIfFailed(ctx, v);
  return (void Function(_Right v) fnR) {
    if (v.isRight)
      fnR(v.right);
  };
}

void Function(Function(_Right v), Function(_Left e)) either(BuildContext? ctx, APIResponse v) {
   _showErrorIfFailed(ctx, v);
  return (void Function(_Right v) fnR, void Function(_Left e) fnL) {
    if (v.isRight)
      fnR(v.right);
    else
      fnL(v.left);
  };
}

class _WsRequest {
  final Map<String, dynamic> req;
  final Completer<APIResponse> res;

  _WsRequest(this.req, this.res);
}

class WsClient {
  WebSocketChannel? _ws;
  Mutex _mutex = Mutex();
  var _inFlight = Map<int, _WsRequest>();
  int _reqId = 0;
  BuildContext? errCtx = null;

  WsClient() {
    _connect();
  }

  Future<APIResponse> request(String? token, String method, String path, Map<String, String> query, Map<String, dynamic> body) async {
    late Future<APIResponse> res;
    await _mutex.protect(() async {
      var id = _reqId++;
      Map<String, dynamic> req = {
        "id": id,
        "method": method,
        "path": path,
        "query": query,
        "body": body
      };
      if (token != null)
        req["token"] = token;
      _ws?.sink.add(jsonEncode(req));
      var c = Completer<APIResponse>();
      final r = _WsRequest(req, c);
      _inFlight[id] = r;
      res = c.future;
    });
    return res;
  }

  void _connect() async
  {
    log("/api: connecting..");
    _mutex.protect(() async {
      _ws?.sink.close();
      _ws = null;
      final w = WebSocketChannel.connect(
        Uri.parse(host.toWS_API()),
      );
      for (final r in _inFlight.values)
        w.sink.add(jsonEncode(r.req));
      _ws = w;
      w.stream.listen((message) {
        final e = errCtx;
        if (e != null) {
          errCtx = null;
          Navigator.of(e, rootNavigator: true).pop();
        }
        Map<String, dynamic> m = jsonDecode(message);
        int id = m['id'];
        var inf = _inFlight[id];
        if (inf != null) {
          if (m['status'] >= 200 && m['status'] < 300)
            inf.res.complete(Right(m['body']));
          else
            inf.res.complete(Left(ErrorDesc(m['status'], m['body']['message'])));
          _inFlight.remove(id);
        }
      }, onError: (err) async {
        log("/api: done, err.");
        await _mutex.protect(() async {
          _ws?.sink.close();
          _ws = null;
        });
        final ctx = navigatorKey.currentContext;
        if (ctx != null && errCtx == null) {
          errCtx = ctx;
          final translations = AppLocalizations.of(ctx);
          CoolAlert.show(
            context: ctx,
            type: CoolAlertType.error,
            barrierDismissible: false,
            title: translations.now_offline.title,
            text: translations.now_offline.msg,
            confirmBtnText: translations.now_offline.button,
            confirmBtnColor: Theme.of(ctx).colorScheme.error,
            onConfirmBtnTap: () {
              if (errCtx == ctx)
                errCtx = null;
                Navigator.of(ctx, rootNavigator: true).pop();
            }
          );
        }
        await Future.delayed(Duration(seconds: 2));
        _connect();
      });
      w.sink.done.then((value) async {
        log("/api: done.");
        await _mutex.protect(() async {
          _ws = null;
        });
        await Future.delayed(Duration(seconds: 2));
        _connect();
      });
    });
  }
}

var wsClient = WsClient();