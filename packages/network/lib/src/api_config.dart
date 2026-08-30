import 'package:core/core.dart';

class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    required this.environment,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
  });

  final String baseUrl;
  final AppEnvironment environment;
  final Duration connectTimeout;
  final Duration receiveTimeout;
}
