class ApiConfig {
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String clientKey = String.fromEnvironment('NAVODAYAN_CLIENT_KEY',
      defaultValue: String.fromEnvironment('CLIENT_KEY'));

  // Default live API URL from navodayan.org web bundle
  static const String productionApiUrl = 'https://2v7xgmkczk.us-east-1.awsapprunner.com/api';

  static String get baseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl;
    }
    return productionApiUrl;
  }
}
