import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void main() {
  test('normalizes a local development API URL', () {
    final config = ApiConfig.forEnvironment(
      name: 'development',
      url: 'http://192.168.1.20:8000/api/v1',
    );
    expect(config.environment, AppEnvironment.development);
    expect(config.baseUrl, 'http://192.168.1.20:8000/api/v1/');
  });

  test('requires explicit environment and HTTPS production URL', () {
    expect(
      () => ApiConfig.forEnvironment(name: '', url: 'https://example.com'),
      throwsStateError,
    );
    expect(
      () => ApiConfig.forEnvironment(
        name: 'production',
        url: 'http://api.example.com/api/v1/',
      ),
      throwsStateError,
    );
    expect(
      ApiConfig.forEnvironment(
        name: 'production',
        url: 'https://api.example.com/api/v1/',
      ).baseUrl,
      'https://api.example.com/api/v1/',
    );
  });
}
