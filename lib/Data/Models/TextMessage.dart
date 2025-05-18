class TextMessage {
  final String id;
  final int datetime;
  final String msg;
  final int play_count;
  final bool is_from_patient;

  TextMessage(this.id, this.datetime, this.msg, this.play_count, this.is_from_patient);

  TextMessage.fromJson(Map<String, dynamic> value) :
    id = value['id'],
    datetime = value['datetime'],
    msg = value['message'],
    play_count = value['play_count'],
    is_from_patient = value['is_from_patient'];
}