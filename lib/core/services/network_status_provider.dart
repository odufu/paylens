import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mspay/core/constants/api_constants.dart';

// Import dart:io conditionally at runtime to prevent UnsupportedError on Web
import 'dart:io' show Socket, InternetAddress;

class NetworkStatusProvider extends ChangeNotifier with WidgetsBindingObserver {
  bool _isOnline = true;
  Timer? _timer;
  bool _isChecking = false;

  bool get isOnline => _isOnline;

  NetworkStatusProvider() {
    WidgetsBinding.instance.addObserver(this);
    _startMonitoring();
  }

  void _startMonitoring() {
    // Check connection immediately
    checkConnection();
    
    // Periodically check connection every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkConnection();
    });
  }

  Future<void> checkConnection() async {
    if (_isChecking) return;
    _isChecking = true;

    bool nextState = false;

    if (kIsWeb) {
      try {
        // Web connectivity: Perform a lightweight request to the Supabase rest endpoint (which supports CORS)
        final uri = Uri.parse(ApiConstants.supabaseUrl).replace(path: '/rest/v1/');
        await http.head(uri).timeout(const Duration(seconds: 3));
        nextState = true;
      } catch (_) {
        nextState = false;
      }
    } else {
      // Mobile/Desktop connectivity using TCP socket connection to bypass emulator DNS issues
      try {
        final socket = await Socket.connect('1.1.1.1', 53, timeout: const Duration(seconds: 2));
        socket.destroy();
        nextState = true;
      } catch (_) {
        try {
          final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
          socket.destroy();
          nextState = true;
        } catch (_) {
          try {
            final uri = Uri.parse(ApiConstants.supabaseUrl);
            final result = await InternetAddress.lookup(uri.host)
                .timeout(const Duration(seconds: 2));
            nextState = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
          } catch (_) {
            nextState = false;
          }
        }
      }
    }

    if (_isOnline != nextState) {
      _isOnline = nextState;
      notifyListeners();
    }
    _isChecking = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkConnection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
