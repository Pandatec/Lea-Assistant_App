import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

abstract class StatefulWidgetRes<T> extends StatefulWidget {
  StatefulWidgetRes({Key? key}) :
    super(key: key);

  @nonVirtual
  State createState() => createResponder();

  StateRes<StatefulWidgetRes<T>, T> createResponder();
}

abstract class StateRes<W extends StatefulWidgetRes<T>, T> extends State<W> {
  void respond(T res) {
    Navigator.of(context).pop(res);
  }
}

Future<T> pushNav<W extends StatefulWidgetRes<T>, T>(BuildContext ctx, W Function(BuildContext ctx) builder, T fallback) async {
  final res = await Navigator.of(ctx).push(MaterialPageRoute(
    builder: builder
  ));
  if (res == null)
    return fallback;
  else
    return res;
}