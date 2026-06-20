import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'cloudinary_service.dart';
import 'esp32_camera_widget.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _cargoController = TextEditingController();
  final _carreraController = TextEditingController();
  final _departamentoController = TextEditingController();
  
  // Datos biométricos
  File? _fotoRostro;
  String? _fotoRostroUrl;  // URL de Cloudinary si se captura con ESP32
  String? _huellaDigital;
  bool _isLoading = false;
  bool _rostroCapturado = false;
  bool _huellaCapturada = false;
  
  final ImagePicker _picker = ImagePicker();
  
  // Configuración del ESP32 (cambia por la IP de tu dispositivo)
  final String _esp32Ip = '192.168.1.100'; // 👈 REEMPLAZA CON LA IP REAL

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _cargoController.dispose();
    _carreraController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  // Muestra diálogo para elegir método de captura
  Future<void> _mostrarOpcionesCaptura() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Selecciona método de captura',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone_android, color: Colors.blue),
              title: const Text('Usar cámara del teléfono'),
              onTap: () {
                Navigator.pop(context);
                _capturarRostroConTelefono();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.green),
              title: const Text('Usar cámara ESP32'),
              subtitle: const Text('Captura desde el dispositivo remoto'),
              onTap: () {
                Navigator.pop(context);
                _capturarRostroConESP32();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Captura con cámara del teléfono (código original)
  Future<void> _capturarRostroConTelefono() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (foto != null) {
        final inputImage = InputImage.fromFile(File(foto.path));
        final faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableLandmarks: true,
            enableClassification: true,
          ),
        );
        
        final faces = await faceDetector.processImage(inputImage);
        await faceDetector.close();
        
        if (faces.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se detectó ningún rostro. Intenta de nuevo.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        setState(() {
          _fotoRostro = File(foto.path);
          _fotoRostroUrl = null;
          _rostroCapturado = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rostro capturado correctamente (cámara teléfono)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error capturando rostro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  // Captura con ESP32 (stream + captura remota)
  Future<void> _capturarRostroConESP32() async {
    // Mostrar diálogo con el stream de la ESP32 y botón de captura
    String? capturedUrl;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 400,
              height: 550,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Capturar rostro desde ESP32-CAM',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ESP32CameraWidget(
                      esp32Ip: _esp32Ip,
                      width: double.infinity,
                      height: 350,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Tomar foto
                      final esp32Cam = ESP32CameraWidget(esp32Ip: _esp32Ip);
                      final url = await esp32Cam.capturePhoto();
                      if (url != null) {
                        capturedUrl = url;
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al capturar foto del ESP32'),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                    icon: const Icon(Icons.camera),
                    label: const Text('CAPTURAR AHORA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    
    if (capturedUrl != null) {
      setState(() {
        _fotoRostroUrl = capturedUrl;
        _fotoRostro = null;
        _rostroCapturado = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Rostro capturado desde ESP32'), backgroundColor: Colors.green),
      );
    }
  }

  // Captura de huella (simulada, igual que antes)
  Future<void> _capturarHuella() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Capturar Huella Digital'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('Coloca tu dedo en el lector'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: Colors.grey.shade300,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
    
    await Future.delayed(const Duration(seconds: 2));
    final huellaHash = DateTime.now().millisecondsSinceEpoch.toString();
    
    setState(() {
      _huellaDigital = huellaHash;
      _huellaCapturada = true;
    });
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Huella digital capturada correctamente'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_rostroCapturado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes capturar el rostro del usuario'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (!_huellaCapturada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes capturar la huella digital'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final authResult = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: '123456',
      );
      final userId = authResult.user!.uid;
      
      String? fotoUrl;
      if (_fotoRostro != null) {
        // Subir imagen local a Cloudinary
        final cloudinaryService = CloudinaryService();
        fotoUrl = await cloudinaryService.uploadImage(
          _fotoRostro!,
          userId: userId,
          folder: 'visual_central/rostros',
        );
      } else if (_fotoRostroUrl != null) {
        // Ya es una URL de Cloudinary (capturada con ESP32)
        fotoUrl = _fotoRostroUrl;
      }
      
      if (fotoUrl == null && (_fotoRostro != null || _fotoRostroUrl != null)) {
        throw Exception('No se pudo obtener la URL de la imagen');
      }
      
      await FirebaseFirestore.instance.collection('usuarios').doc(userId).set({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'cargo': _cargoController.text.trim(),
        'carrera': _carreraController.text.trim(),
        'departamento': _departamentoController.text.trim(),
        'rol': 'empleado',
        'estado': 'activo',
        'intentosFallidos': 0,
        'ultimoAcceso': null,
        'datosBiometricos': {
          'rostroRegistrado': true,
          'rostroUrl': fotoUrl,
          'fechaRegistroRostro': FieldValue.serverTimestamp(),
          'huellaRegistrada': true,
          'huellaHash': _huellaDigital,
          'fechaRegistroHuella': FieldValue.serverTimestamp(),
          'precisionPromedio': 0.0,
        },
        'metadata': {
          'creadoPor': FirebaseAuth.instance.currentUser?.uid ?? 'sistema',
          'fechaCreacion': FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await FirebaseFirestore.instance.collection('logs').add({
        'tipo': 'usuario_creado',
        'usuarioId': userId,
        'usuarioNombre': _nombreController.text.trim(),
        'creadoPor': FirebaseAuth.instance.currentUser?.email ?? 'admin',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Usuario creado exitosamente'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error guardando usuario: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Widget de previsualización de la foto (acepta archivo local o URL)
  Widget _buildFotoPreview() {
    if (_fotoRostro != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: Image.file(_fotoRostro!, height: 150, width: double.infinity, fit: BoxFit.cover),
      );
    } else if (_fotoRostroUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: Image.network(_fotoRostroUrl!, height: 150, width: double.infinity, fit: BoxFit.cover),
      );
    } else {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('Sin foto de rostro'),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Usuario'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información personal (igual)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Información Personal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Ingresa el nombre completo' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingresa el correo';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _cargoController,
                        decoration: const InputDecoration(labelText: 'Cargo', prefixIcon: Icon(Icons.work), border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Ingresa el cargo' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _carreraController,
                        decoration: const InputDecoration(labelText: 'Carrera', prefixIcon: Icon(Icons.school), border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Ingresa la carrera' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _departamentoController,
                        decoration: const InputDecoration(labelText: 'Departamento', prefixIcon: Icon(Icons.business), border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Ingresa el departamento' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Datos Biométricos
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Datos Biométricos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      // Capturar Rostro
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _rostroCapturado ? Colors.green : Colors.grey, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildFotoPreview(),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _mostrarOpcionesCaptura,
                                      icon: const Icon(Icons.camera),
                                      label: const Text('Capturar Rostro'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _rostroCapturado ? Colors.green : Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (_rostroCapturado) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _fotoRostro = null;
                                          _fotoRostroUrl = null;
                                          _rostroCapturado = false;
                                        });
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Capturar Huella (igual)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _huellaCapturada ? Colors.green : Colors.grey, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                              ),
                              child: Center(
                                child: Icon(Icons.fingerprint, size: 50, color: _huellaCapturada ? Colors.green : Colors.grey),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _capturarHuella,
                                      icon: const Icon(Icons.fingerprint),
                                      label: const Text('Capturar Huella'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _huellaCapturada ? Colors.green : Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (_huellaCapturada) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _huellaDigital = null;
                                          _huellaCapturada = false;
                                        });
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _guardarUsuario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('GUARDAR USUARIO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'La contraseña por defecto es "123456". El usuario deberá cambiarla en su primer inicio de sesión.',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}