import 'package:network/network.dart';

abstract final class ProductConfig {
  static const appName = String.fromEnvironment(
    'DEEKSHA_APP_NAME',
    defaultValue: String.fromEnvironment(
      'VELA_FM_APP_NAME',
      defaultValue: 'Deeksha',
    ),
  );

  static ApiConfig api() => ApiConfig.fromBuildEnvironment();

  static String tokenKey(ApiConfig config) =>
      'vela_fm.auth.${config.environment.name}.${Uri.parse(config.baseUrl).authority}';
}
