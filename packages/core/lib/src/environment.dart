enum AppEnvironment { development, staging, production }

extension AppEnvironmentX on AppEnvironment {
  bool get isDevelopment => this == AppEnvironment.development;
  bool get isProduction => this == AppEnvironment.production;
}
