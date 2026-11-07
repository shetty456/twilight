import 'package:network/network.dart';

abstract final class ProductConfig {
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '717208934627-sh38nmeif0f21bvmkdav38613r15re7u.apps.googleusercontent.com',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const googleAuthEnabled = bool.fromEnvironment(
    'DEEKSHA_GOOGLE_AUTH_ENABLED',
    defaultValue: true,
  );
  static const appName = String.fromEnvironment(
    'DEEKSHA_APP_NAME',
    defaultValue: 'Deeksha',
  );

  static ApiConfig api() => ApiConfig.fromBuildEnvironment();

  static String tokenKey(ApiConfig config) =>
      'deeksha.auth.${config.environment.name}.${Uri.parse(config.baseUrl).authority}';
}
