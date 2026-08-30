import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'dio_client.dart';

final apiConfigProvider = Provider<ApiConfig>(
  (_) => throw UnimplementedError('Override apiConfigProvider in your app'),
);

final dioClientProvider = Provider<DioClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  return DioClient(config);
});
