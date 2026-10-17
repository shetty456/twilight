import 'package:core/core.dart';

class ApiConfig {
  static const defaultBaseUrl =
      'https://origin-production-5ab8.up.railway.app/api/v1/';

  const ApiConfig({
    required this.baseUrl,
    required this.environment,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  final String baseUrl;
  final AppEnvironment environment;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Build-time settings shared by every product app.
  /// Override APP_ENV and API_BASE_URL with --dart-define when needed.
  factory ApiConfig.fromBuildEnvironment() {
    const name = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultBaseUrl,
    );
    return ApiConfig.forEnvironment(name: name, url: url);
  }

  factory ApiConfig.forEnvironment(
      {required String name, required String url}) {
    final environment = switch (name) {
      'development' => AppEnvironment.development,
      'production' => AppEnvironment.production,
      _ => throw StateError('APP_ENV must be development or production.'),
    };
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw StateError('API_BASE_URL must be an absolute HTTP(S) URL.');
    }
    if (environment.isProduction && uri.scheme != 'https') {
      throw StateError('Production API_BASE_URL must use HTTPS.');
    }
    final normalized = url.endsWith('/') ? url : '$url/';
    return ApiConfig(baseUrl: normalized, environment: environment);
  }
}
