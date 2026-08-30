import 'package:analytics/analytics.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network/network.dart';

import 'env_config.dart';
import 'product_config.dart';
import 'stub_auth_repository.dart';

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
    authRepositoryProvider.overrideWithValue(const StubAuthRepository()),
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
