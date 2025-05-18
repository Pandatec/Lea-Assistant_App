/* String emailToName(String email) {
  String res = email.split('@')[0];
  return res[0].toUpperCase();
} */

extension StringExtension on String {
  String emailToName() {
    String res = "${this[0].toUpperCase()}${this.substring(1)}";
    return res.split('@')[0];
  }
}
