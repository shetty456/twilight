import 'environment.dart';

abstract class AppConfig {
  const AppConfig();

  String get appName;
  String get apiBaseUrl;
  AppEnvironment get environment;
}
