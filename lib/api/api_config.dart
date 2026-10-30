import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();
  static const String configuredBaseUrl = String.fromEnvironment(
    'PHYSIO_API_BASE_URL',
  );
  static String get baseUrl => normalizeBaseUrl(
    configuredBaseUrl.isNotEmpty
        ? configuredBaseUrl
        : kIsWeb
        ? 'http://localhost:3002/api/v1'
        : defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3002/api/v1'
        : 'http://127.0.0.1:3002/api/v1',
  );

  static String normalizeBaseUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError('Invalid Physio API URL.');
    }
    var path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    path = path.replaceFirst(RegExp(r'/physio$', caseSensitive: false), '');
    if (path.isEmpty) {
      path = '/api/v1';
    } else if (!path.endsWith('/api/v1')) {
      path = '$path/api/v1';
    }
    final port =
        uri.scheme == 'http' ||
            const {3000, 3001, 3002, 3004}.contains(uri.port)
        ? 3002
        : uri.port;
    return uri.replace(port: port, path: path).toString();
  }

  static const Duration timeout = Duration(seconds: 20);
}
