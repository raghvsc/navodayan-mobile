class ApiConfig {
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String defaultClientKey = 'nv_live_web_xW-HACK6YIEjxr3odbmiOGoUlQOjqccr';

  static const String _definedClientKey = String.fromEnvironment(
    'NAVODAYAN_CLIENT_KEY',
    defaultValue: String.fromEnvironment('CLIENT_KEY'),
  );

  static String get clientKey =>
      _definedClientKey.isNotEmpty ? _definedClientKey : defaultClientKey;

  // Default live API URL from navodayan.org web bundle
  static const String productionApiUrl = 'https://2v7xgmkczk.us-east-1.awsapprunner.com/api';

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl;
    }
    return productionApiUrl;
  }
}
