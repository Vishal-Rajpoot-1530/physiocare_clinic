class ApiConfig {
  ApiConfig._();
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3002/api/v1',
  );
  static String get baseUrl => configuredBaseUrl.replaceAll(RegExp(r'/+$'), '');
  static const Duration timeout = Duration(seconds: 20);
}
