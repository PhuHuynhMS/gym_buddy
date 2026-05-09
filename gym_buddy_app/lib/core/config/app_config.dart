class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final apiBaseUrl = json['apiBaseUrl'];
    if (apiBaseUrl is! String || apiBaseUrl.trim().isEmpty) {
      throw const FormatException('apiBaseUrl is required in app config');
    }

    return AppConfig(apiBaseUrl: apiBaseUrl.trim());
  }
}
