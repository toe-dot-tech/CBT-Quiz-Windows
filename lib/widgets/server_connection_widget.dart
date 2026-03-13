import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cbtapp/utils/app_colors.dart';
import 'package:http/http.dart' as http;

class ServerConnectionWidget extends StatefulWidget {
  final Widget child;
  final String serverHost;
  final int serverPort;
  final Duration checkInterval;

  const ServerConnectionWidget({
    super.key,
    required this.child,
    required this.serverHost,
    this.serverPort = 8080,
    this.checkInterval = const Duration(seconds: 10),
  });

  @override
  State<ServerConnectionWidget> createState() => _ServerConnectionWidgetState();
}

class _ServerConnectionWidgetState extends State<ServerConnectionWidget> {
  bool _isServerConnected = true;
  final bool _wasDisconnected = false;
  Timer? _checkTimer;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _checkServerConnection();
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(widget.checkInterval, (_) {
      _checkServerConnection();
    });
  }

  Future<void> _checkServerConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://${widget.serverHost}:${widget.serverPort}/api/health'),
          )
          .timeout(const Duration(seconds: 3));

      final wasConnected = _isServerConnected;
      setState(() {
        _isServerConnected = response.statusCode == 200;
      });

      if (!wasConnected && _isServerConnected) {
        // Just reconnected
        _showReconnectedSnackbar();
      } else if (wasConnected && !_isServerConnected) {
        // Just disconnected
        _showDisconnectedSnackbar();
        _startReconnectAttempts();
      }
    } catch (e) {
      final wasConnected = _isServerConnected;
      setState(() {
        _isServerConnected = false;
      });

      if (wasConnected) {
        _showDisconnectedSnackbar();
        _startReconnectAttempts();
      }
    }
  }

  void _startReconnectAttempts() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkServerConnection();
      if (_isServerConnected) {
        timer.cancel();
        _reconnectTimer = null;
      }
    });
  }

  void _showDisconnectedSnackbar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Lost connection to exam server. Attempting to reconnect...",
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReconnectedSnackbar() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Expanded(
              child: Text("Reconnected to exam server."),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isServerConnected) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 80,
                  color: AppColors.error,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Server Connection Lost",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Unable to connect to the exam server at\n${widget.serverHost}:${widget.serverPort}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Please check if:",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint("The server application is running"),
                _buildBulletPoint("You're connected to the correct network"),
                _buildBulletPoint("Your firewall isn't blocking the connection"),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _checkServerConnection,
                  icon: const Icon(Icons.refresh),
                  label: const Text("RETRY CONNECTION"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPrimary,
                    minimumSize: const Size(200, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: AppColors.darkPrimary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}