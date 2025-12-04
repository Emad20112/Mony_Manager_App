import 'dart:async';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  bool _isConnected = true; // Default to connected for mock implementation

  Stream<bool> get connectivityStream => _connectivityController.stream;
  Stream<bool> get connectionStream =>
      _connectivityController.stream; // Alias for compatibility
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Mock implementation - simulate connectivity check
    _isConnected = true;
    _connectivityController.add(_isConnected);

    if (kDebugMode) {
      print('Connectivity service initialized (mock implementation)');
    }
  }

  Future<bool> checkConnectivity() async {
    // Mock implementation - always return true
    return true;
  }

  // Simulate connectivity change for testing
  void simulateConnectivityChange(bool isConnected) {
    _isConnected = isConnected;
    _connectivityController.add(_isConnected);
  }

  void dispose() {
    _connectivityController.close();
  }
}
