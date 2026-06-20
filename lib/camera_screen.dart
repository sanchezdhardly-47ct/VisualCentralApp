import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'biometric_service.dart';
import 'dashboard_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final biometricService = BiometricService();
      final camera = await biometricService.getCamera();
      
      if (camera != null) {
        _controller = CameraController(
          camera,
          ResolutionPreset.medium,
        );
        
        await _controller!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
    }
  }

  Future<void> _captureAndVerify() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDetecting) {
      return;
    }
    
    setState(() => _isDetecting = true);
    
    try {
      // Tomar foto
      final XFile image = await _controller!.takePicture();
      final biometricService = BiometricService();
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      
      // Detectar rostro
      final tieneRostro = await biometricService.detectarRostro(image);
      
      if (!tieneRostro) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se detectó ningún rostro'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Analizar rostro
      final analisis = await biometricService.analizarRostro(image);
      
      // Guardar evidencia
      final imageFile = File(image.path);
      final url = await biometricService.guardarImagenBiometrica(
        'user123', // Aquí iría el ID real del usuario
        imageFile,
      );
      
      // Simular verificación exitosa (90% de probabilidad)
      final exitoso = DateTime.now().millisecondsSinceEpoch % 10 != 0;
      
      // Registrar acceso
      await dashboardProvider.registrarAcceso(
        usuarioId: 'user123',
        usuarioNombre: 'Javier Pérez',
        precision: exitoso ? 98.7 : 65.3,
        exitoso: exitoso,
        motivo: exitoso ? null : 'Baja precisión',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exitoso 
              ? '✅ Acceso biométrico exitoso' 
              : '❌ Acceso denegado'),
            backgroundColor: exitoso ? Colors.green : Colors.red,
          ),
        );
        Navigator.pop(context, exitoso);
      }
      
    } catch (e) {
      debugPrint('Error en captura: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  void _toggleCamera() {
    // Por ahora no implementamos cambio de cámara
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación Biométrica'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isFrontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: _toggleCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Vista previa de la cámara
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!)
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Inicializando cámara...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          
          // Guía de rostro
          if (_isInitialized)
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.all(50),
            ),
          
          // Botón de captura
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: _isDetecting
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                    )
                  : FloatingActionButton(
                      onPressed: _captureAndVerify,
                      child: const Icon(Icons.camera_alt),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 5,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
