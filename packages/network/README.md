# Shared network tools

The `network` package uses Dio with an app-supplied base URL and authentication tokens. It does not assume a particular backend provider.

`DeviceNetworkAvailability` reports whether the device has a network transport. This is useful for an offline banner, but it does not prove that an API is reachable. Keep handling timeouts and request errors.

Attach `RequestMetricsInterceptor` to a Dio client when an app needs diagnostics:

```dart
client.dio.interceptors.add(RequestMetricsInterceptor((metric) {
  // Send method, path, status, and duration to your app's observer.
}));
```

The interceptor omits query values, headers, and request/response bodies. It does not send data to a monitoring service by itself.
