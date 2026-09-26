import 'package:core/core.dart';
import 'package:network/network.dart';

/// App-facing config derived from the same build settings as the API client.
class TemplateConfig extends AppConfig {
  const TemplateConfig(this.api);

  final ApiConfig api;

  @override
  String get appName =>
      api.environment.isProduction ? 'Template' : 'Template (Dev)';

  @override
  String get apiBaseUrl => api.baseUrl;

  @override
  AppEnvironment get environment => api.environment;
}
