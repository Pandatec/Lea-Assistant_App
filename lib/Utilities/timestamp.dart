DateTime dateTimeFromSecondsSinceEpoch(int src) {
  return DateTime.fromMillisecondsSinceEpoch(src * 1000, isUtc: true).toLocal();
}

int dateTimeSecondsSinceEpoch(DateTime src) {
  return (src.toUtc().millisecondsSinceEpoch / 1000).round().toInt();
}