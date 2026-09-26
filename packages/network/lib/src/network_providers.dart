import 'package:auth/auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'dio_client.dart';

final apiConfigProvider = Provider<ApiConfig>(
  (_) => throw UnimplementedError('Override apiConfigProvider in your app'),
);

final authTokenStoreProvider = Provider<AuthTokenStore?>((_) => null);

final dioClientProvider = Provider<DioClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  final tokens = ref.watch(authTokenStoreProvider);
  return DioClient(config, tokenStore: tokens);
});
