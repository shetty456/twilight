import 'package:analytics/analytics.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';

import 'env_config.dart';
import 'product_config.dart';
import 'stub_auth_repository.dart';

final productConfigProvider = Provider<ProductConfig>((ref) {
  final api = ref.watch(apiConfigProvider);
  final appConfig = TemplateConfig(api);
  return ProductConfig(
    appName: appConfig.appName,
    bundleId: 'com.twilight.template',
    appConfig: appConfig,
  );
});

List<Override> buildProviderOverrides() {
  final api = ApiConfig.fromBuildEnvironment();
  return [
    authRepositoryProvider.overrideWithValue(const StubAuthRepository()),
    apiConfigProvider.overrideWithValue(api),
    authTokenStoreProvider.overrideWithValue(SecureAuthTokenStore(
      key:
          'twilight.auth.${api.environment.name}.${Uri.parse(api.baseUrl).authority}',
    )),
    analyticsServiceProvider.overrideWithValue(
      api.environment.isDevelopment
          ? const DebugAnalyticsService()
          : const NoOpAnalyticsService(),
    ),
  ];
}
