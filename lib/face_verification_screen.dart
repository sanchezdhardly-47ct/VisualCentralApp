import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'esp32_camera_widget.dart';
import 'face_comparison_service.dart'; // 👈 TU SERVICIO DE COMPARACIÓN

class FaceVerificationScreen extends StatefulWidget {
  final String esp32Ip;
  const FaceVerificationScreen({super.key, required this.esp32Ip});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  bool _isVerifying = false;
  String? _resultMessage;
  bool _resultSuccess = false;

  final FaceComparisonService _comparisonService = FaceComparisonService();

  Future<void> _verifyFace() async {
    setState(() {
      _isVerifying = true;
      _resultMessage = null;
    });

    try {
      // 1. Capturar foto actual desde ESP32
      final esp32Cam = ESP32CameraWidget(esp32Ip: widget.esp32Ip);
      final currentFaceUrl = await esp32Cam.capturePhoto();
      if (currentFaceUrl == null) {
        throw Exception('No se pudo capturar la foto del ESP32');
      }

      // 2. Obtener todos los usuarios activos con rostro registrado
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('estado', isEqualTo: 'activo')
          .get();

      bool matchFound = false;
      String matchedUserId = '';
      String matchedUserName = '';
      double bestPrecision = 0.0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final rostroUrl = data['datosBiometricos']?['rostroUrl'];
        if (rostroUrl != null) {
          // Comparar rostros usando tu servicio
          final isMatch = await _comparisonService.compareFaces(rostroUrl, currentFaceUrl);
          if (isMatch) {
            matchFound = true;
            matchedUserId = doc.id;
            matchedUserName = data['nombre'] ?? 'Usuario';
            // Podrías también obtener la precisión si tu servicio la devuelve
            break;
          }
        }
      }

      // 3. Registrar el acceso en Firestore
      if (matchFound) {
        await FirebaseFirestore.instance.collection('accesos').add({
          'usuarioId': matchedUserId,
          'usuarioNombre': matchedUserName,
          'tipo': 'reconocido',
          'timestamp': FieldValue.serverTimestamp(),
          'precision': 98.5, // Aquí podrías poner la precisión real
          'resultado': {'exitoso': true},
          'fotoEvidencia': currentFaceUrl,
        });

        setState(() {
          _resultMessage = '✅ Acceso concedido. Bienvenido $matchedUserName';
          _resultSuccess = true;
        });
      } else {
        await FirebaseFirestore.instance.collection('accesos').add({
          'usuarioId': 'desconocido',
          'usuarioNombre': 'No identificado',
          'tipo': 'denegado',
          'timestamp': FieldValue.serverTimestamp(),
          'precision': 0,
          'resultado': {'exitoso': false, 'motivo': 'Rostro no reconocido'},
          'fotoEvidencia': currentFaceUrl,
        });

        setState(() {
          _resultMessage = '❌ Acceso denegado. Rostro no reconocido';
          _resultSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Error: ${e.toString()}';
        _resultSuccess = false;
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación Facial'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Mira directamente a la cámara',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 350,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ESP32CameraWidget(
                esp32Ip: widget.esp32Ip,
                width: double.infinity,
                height: 350,
                showLiveBadge: true,
              ),
            ),
            const SizedBox(height: 24),
            if (_isVerifying)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _verifyFace,
                icon: const Icon(Icons.face_retouching_natural),
                label: const Text('MARCAR ENTRADA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            if (_resultMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _resultSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _resultSuccess ? Colors.green : Colors.red),
                ),
                child: Text(
                  _resultMessage!,
                  style: TextStyle(
                    color: _resultSuccess ? Colors.green.shade800 : Colors.red.shade800,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}