class ApiConstants {
  static const String https = 'https://';
  static const String http = 'http://';
  static const String wakeonlanRoute = '/wakeonlan';
  static const String shutdownRoute = '/shutdown';
  static const String statusRoute = '/status';
  static const Duration requestTimeout = Duration(seconds: 8);
  static const Duration pollingInterval = Duration(seconds: 10);
}
