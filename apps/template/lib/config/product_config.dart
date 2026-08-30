import 'package:core/core.dart';

class ProductConfig {
  const ProductConfig({
    required this.appName,
    required this.bundleId,
    required this.appConfig,
  });

  final String appName;
  final String bundleId;
  final AppConfig appConfig;
}
