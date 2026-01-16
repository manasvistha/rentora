import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class INetworkInfo {
  Future<bool> get isConnected;
}

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo(Connectivity());
});

class NetworkInfo implements INetworkInfo {
  final Connectivity _connectivity;

  NetworkInfo(this._connectivity);

  @override
  // TODO: implement isConnected
  Future<bool> get isConnected async {
    //
    final result = await _connectivity
        .checkConnectivity(); // is the internet or data is on or not
    if (result.contains(ConnectivityResult.none)) {
      return false;
    }

    // return await _sacchaikaiInternetChakiNai();

    return true;
  }

  Future<bool> _sacchaikaiInternetChakiNai() async {
    try {
      final result = await InternetAddress.lookup('google.come');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
