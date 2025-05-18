const _gh_ref = const String.fromEnvironment('GITHUB_REF', defaultValue: "refs/tags/v0.0.1");

String _ghRefNoPrefix() => _gh_ref.replaceAll("refs/tags/v", "");
String _retrieveVersion() => _ghRefNoPrefix().replaceAll("r", "");

final version = _retrieveVersion();

class Host {
  final bool isSsl;
  final int port;
  final String host;
  final String fullHost;
  final String httpScheme;

  Uri uri(path, Map<String, dynamic> params) {
    return Uri(
        scheme: httpScheme,
        host: host,
        port: port,
        path: path,
        queryParameters: params);
  }

  Host(bool isSsl, String host, [int? port = null])
      : isSsl = isSsl,
        port = port == null ? (isSsl ? 443 : 80) : port,
        host = host,
        fullHost = port == null ? host : host + ':' + port.toString(),
        httpScheme = isSsl ? "https" : "http";

  String toHTTP() {
    return httpScheme + "://" + fullHost + "/v1/";
  }

  String toWS() {
    return (isSsl ? "wss" : "ws") + "://" + fullHost + "/app";
  }

  String toWS_API() {
    return (isSsl ? "wss" : "ws") + "://" + fullHost + "/api";
  }

  static Host retrieve() {
    final llh = const String.fromEnvironment('LEA_LOCAL_HOST');
    final is_release = _ghRefNoPrefix() != version; // Trailing r still contained in no prefix
    if (llh != "") {
      final s = llh.split(':');
      if (s.length == 1)
        return new Host(false, llh);
      else {
        final p = int.tryParse(s[1]);
        if (p == null)
          throw new Exception("Can't parse local port '${s[1]}'");
        return new Host(false, s[0], p);
      }
    } else
      return new Host(true, "${is_release ? '' : "dev."}api.leassistant.fr");
  }
}

final host = Host.retrieve();

final platform = const String.fromEnvironment('PLATFORM', defaultValue: 'unknown');