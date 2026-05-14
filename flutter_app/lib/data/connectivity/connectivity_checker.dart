import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityChecker {
  ConnectivityChecker({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get isOnlineStream {
    return _connectivity.onConnectivityChanged.map(_hasConnection).distinct();
  }

  Future<bool> get isOnline async {
    return _hasConnection(await _connectivity.checkConnectivity());
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
