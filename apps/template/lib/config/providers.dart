import 'package:analytics/analytics.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network/network.dart';

import 'env_config.dart';
import 'product_config.dart';

// Change this to StagingConfig() or ProdConfig() per build flavor
const AppConfig _activeConfig = DevConfig();

final productConfigProvider = Provider<ProductConfig>((_) {
  return const ProductConfig(
    appName: 'Template',
    bundleId: 'com.twilight.template',
    appConfig: _activeConfig,
  );
});

List<Override> buildProviderOverrides() {
  return [
    apiConfigProvider.overrideWithValue(
      ApiConfig(
        baseUrl: _activeConfig.apiBaseUrl,
        environment: _activeConfig.environment,
      ),
    ),
    analyticsServiceProvider.overrideWithValue(
      _activeConfig.environment.isDevelopment
          ? const DebugAnalyticsService()
          : const NoOpAnalyticsService(),
    ),
  ];
}
