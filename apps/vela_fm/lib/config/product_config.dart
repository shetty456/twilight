import 'package:network/network.dart';

abstract final class ProductConfig {
  static const appName = String.fromEnvironment(
    'DEEKSHA_APP_NAME',
    defaultValue: String.fromEnvironment(
      'VELA_FM_APP_NAME',
      defaultValue: 'Deeksha',
    ),
  );

  static ApiConfig api() {
    const environment = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000/api/v1/',
    );
    return ApiConfig.forEnvironment(name: environment, url: baseUrl);
  }

  static String tokenKey(ApiConfig config) =>
      'vela_fm.auth.${config.environment.name}.${Uri.parse(config.baseUrl).authority}';
}
