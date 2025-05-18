class Notif {
  int created_at;
  bool is_read;
  String title;
  String message;
  dynamic context;

  Notif({required this.created_at, required this.is_read, required this.title, required this.message, required this.context});

  Notif.fromJson(Map<String, dynamic> json) :
    created_at = json['created_at'],
    is_read = json['is_read'],
    title = json['title'],
    message = json['message'],
    context = json['context'];
}