import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ESP32CameraWidget extends StatefulWidget {
  final String esp32Ip;
  final double width;
  final double height;
  final bool showLiveBadge;
  
  const ESP32CameraWidget({
    super.key,
    required this.esp32Ip,
    this.width = 400,
    this.height = 300,
    this.showLiveBadge = true,
  });

  @override
  State<ESP32CameraWidget> createState() => _ESP32CameraWidgetState();
}

class _ESP32CameraWidgetState extends State<ESP32CameraWidget> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _initWebView();
  }

  Future<void> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse('http://${widget.esp32Ip}/status'));
      setState(() {
        _isOnline = response.statusCode == 200;
      });
    } catch (e) {
      setState(() {
        _isOnline = false;
      });
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('http://${widget.esp32Ip}/'));
  }

  Future<String?> capturePhoto() async {
    try {
      final response = await http.get(Uri.parse('http://${widget.esp32Ip}/capture'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      print('Error capturando: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isOnline ? Colors.green : Colors.red, width: 2),
      ),
      child: Stack(
        children: [
          if (_isOnline)
            WebViewWidget(controller: _controller)
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text('ESP32 no conectado', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          if (_isLoading && _isOnline)
            const Center(child: CircularProgressIndicator()),
          if (widget.showLiveBadge && _isOnline)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 10),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
