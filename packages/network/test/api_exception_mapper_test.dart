import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';

void main() {
  test('handles DRF field errors without masking the HTTP status', () {
    final request = RequestOptions(path: 'auth/otp/email/verify/');
    final error = DioException(
      requestOptions: request,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: 400,
        data: {
          'otp': ['Invalid OTP.'],
        },
      ),
      type: DioExceptionType.badResponse,
    );

    final mapped = mapDioException(error);
    expect(mapped.message, 'Server error');
    expect(mapped.statusCode, 400);
  });
}
