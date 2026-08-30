import 'package:core/core.dart';

class DevConfig extends AppConfig {
  const DevConfig();

  @override
  String get appName => 'Template (Dev)';

  @override
  String get apiBaseUrl => 'https://api-dev.example.com';

  @override
  AppEnvironment get environment => AppEnvironment.development;
}

class StagingConfig extends AppConfig {
  const StagingConfig();

  @override
  String get appName => 'Template (Staging)';

  @override
  String get apiBaseUrl => 'https://api-staging.example.com';

  @override
  AppEnvironment get environment => AppEnvironment.staging;
}

class ProdConfig extends AppConfig {
  const ProdConfig();

  @override
  String get appName => 'Template';

  @override
  String get apiBaseUrl => 'https://api.example.com';

  @override
  AppEnvironment get environment => AppEnvironment.production;
}
