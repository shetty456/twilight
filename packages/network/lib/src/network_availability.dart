import 'package:connectivity_plus/connectivity_plus.dart';

/// Available network transport. Requests can still fail or time out.
abstract class NetworkAvailability {
  Future<bool> get isAvailable;
  Stream<bool> get changes;
}

class DeviceNetworkAvailability implements NetworkAvailability {
  DeviceNetworkAvailability({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _hasTransport(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Future<bool> get isAvailable async =>
      _hasTransport(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes =>
      _connectivity.onConnectivityChanged.map(_hasTransport).distinct();
}
