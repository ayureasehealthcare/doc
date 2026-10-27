import 'dart:async';
import 'package:doctro/core/constants/app_icons.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:doctro/core/astra/utils/astra_logger.dart';
import 'package:doctro/theme/ayureze_theme.dart';

/// Connection Monitor
///
/// Monitors network connectivity and provides offline detection.
/// Integrates with Astra AI for offline-first experience.
class ConnectionMonitor extends ChangeNotifier {
  static final ConnectionMonitor _instance = ConnectionMonitor._internal();

  factory ConnectionMonitor() => _instance;
  ConnectionMonitor._internal();

  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  ConnectionType _connectionType = ConnectionType.unknown;
  ConnectionType get connectionType => _connectionType;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Start monitoring connectivity
  Future<void> initialize() async {
    // Check initial status
    final results = await _connectivity.checkConnectivity();
    _updateConnection(results);

    // Listen for changes
    _subscription =
        _connectivity.onConnectivityChanged.listen(_updateConnection);

    AstraLogger.i('Connection monitor initialized', tag: 'ConnectionMonitor');
  }

  /// Stop monitoring
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _updateConnection(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    if (results.contains(ConnectivityResult.none)) {
      _isOnline = false;
      _connectionType = ConnectionType.none;
    } else {
      _isOnline = true;

      if (results.contains(ConnectivityResult.wifi)) {
        _connectionType = ConnectionType.wifi;
      } else if (results.contains(ConnectivityResult.mobile)) {
        _connectionType = ConnectionType.mobile;
      } else if (results.contains(ConnectivityResult.ethernet)) {
        _connectionType = ConnectionType.ethernet;
      } else {
        _connectionType = ConnectionType.other;
      }
    }

    if (wasOnline != _isOnline) {
      AstraLogger.i(
        'Connection changed: ${_isOnline ? "Online" : "Offline"} (${_connectionType.name})',
        tag: 'ConnectionMonitor',
      );
      notifyListeners();
    }
  }

  /// Check connection manually
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnection(results);
    return _isOnline;
  }

  /// Wait for connection to be restored
  Future<void> waitForConnection({Duration? timeout}) async {
    if (_isOnline) return;

    final completer = Completer<void>();
    StreamSubscription<List<ConnectivityResult>>? sub;

    sub = _connectivity.onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        completer.complete();
        sub?.cancel();
      }
    });

    if (timeout != null) {
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Connection timeout'));
        }
      });
    }

    return completer.future;
  }
}

/// Connection types
enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  none,
  unknown,
  other;

  String get label {
    switch (this) {
      case ConnectionType.wifi:
        return 'WiFi';
      case ConnectionType.mobile:
        return 'Mobile Data';
      case ConnectionType.ethernet:
        return 'Ethernet';
      case ConnectionType.none:
        return 'No Connection';
      case ConnectionType.unknown:
        return 'Unknown';
      case ConnectionType.other:
        return 'Other';
    }
  }

  List<List<dynamic>> get icon {
    switch (this) {
      case ConnectionType.wifi:
        return AppIcons.wifi;
      case ConnectionType.mobile:
        return HugeIcons.strokeRoundedSignalFull02;
      case ConnectionType.ethernet:
        return HugeIcons.strokeRoundedNetwork;
      case ConnectionType.none:
        return HugeIcons.strokeRoundedWifiOff01;
      case ConnectionType.unknown:
        return HugeIcons.strokeRoundedHelpCircle;
      case ConnectionType.other:
        return HugeIcons.strokeRoundedQuestion;
    }
  }
}

/// Connection status banner
class ConnectionStatusBanner extends StatelessWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionMonitor>(
      builder: (context, monitor, _) {
        if (monitor.isOnline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: AyurezeTheme.spaceSm, horizontal: AyurezeTheme.spaceLg),
          color: Colors.orange.shade700,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const HugeIcon(
                    icon: HugeIcons.strokeRoundedWifiOff01,
                    color: Colors.white,
                    size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'You are offline. Messages will be sent when connected.',
                    style: TextStyle(
                        color: Colors.white, fontSize: AyurezeTheme.textMd),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Retry on connection restore
class RetryOnConnection extends StatefulWidget {
  final Widget child;
  final VoidCallback onRetry;
  final String? retryMessage;

  const RetryOnConnection({
    super.key,
    required this.child,
    required this.onRetry,
    this.retryMessage,
  });

  @override
  State<RetryOnConnection> createState() => _RetryOnConnectionState();
}

class _RetryOnConnectionState extends State<RetryOnConnection> {
  @override
  void initState() {
    super.initState();
    ConnectionMonitor().addListener(_onConnectionChange);
  }

  @override
  void dispose() {
    ConnectionMonitor().removeListener(_onConnectionChange);
    super.dispose();
  }

  void _onConnectionChange() {
    if (ConnectionMonitor().isOnline && mounted) {
      widget.onRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
