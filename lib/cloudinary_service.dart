import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';  // 👈 AGREGAR para XFile

class CloudinaryService {
  // ⚠️ REEMPLAZA CON TUS DATOS REALES DE CLOUDINARY ⚠️
  static const String cloudName = 'dica0hrkf';
  static const String uploadPreset = 'esp32camuploads';
  static const String apiKey = '698832663345538';
  static const String apiSecret = '_gPMHe1WnIT6Cbp0YLIfsm0K4HQ';
  
  late final CloudinaryPublic _cloudinary;
  
  CloudinaryService() {
    _cloudinary = CloudinaryPublic(cloudName, uploadPreset);
  }
  
  // Subir imagen desde archivo
  Future<String?> uploadImage(File imageFile, {String? userId, String? folder}) async {
    try {
      final publicId = userId != null 
          ? '${userId}_${DateTime.now().millisecondsSinceEpoch}'
          : '${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder ?? 'visual_central/rostros',
          resourceType: CloudinaryResourceType.Image,
          publicId: publicId,
        ),
      );
      
      debugPrint('✅ Imagen subida a Cloudinary: ${response.secureUrl}');
      return response.secureUrl;
      
    } catch (e) {
      debugPrint('❌ Error subiendo a Cloudinary: $e');
      return null;
    }
  }
  
  // Subir imagen desde XFile
  Future<String?> uploadXFile(XFile imageFile, {String? userId, String? folder}) async {
    try {
      final publicId = userId != null 
          ? '${userId}_${DateTime.now().millisecondsSinceEpoch}'
          : '${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,  // XFile tiene .path
          folder: folder ?? 'visual_central/rostros',
          resourceType: CloudinaryResourceType.Image,
          publicId: publicId,
        ),
      );
      
      debugPrint('✅ Imagen subida a Cloudinary: ${response.secureUrl}');
      return response.secureUrl;
      
    } catch (e) {
      debugPrint('❌ Error subiendo a Cloudinary: $e');
      return null;
    }
  }
  
  // Para ESP32: Recibir bytes y guardar temporalmente
  Future<String?> uploadBytes(List<int> imageBytes, {String? userId, String? folder}) async {
    // Crear archivo temporal
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/esp32_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    try {
      // Escribir bytes al archivo temporal
      await tempFile.writeAsBytes(imageBytes);
      
      // Subir el archivo temporal
      final publicId = userId != null 
          ? '${userId}_${DateTime.now().millisecondsSinceEpoch}'
          : 'esp32_${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          tempFile.path,
          folder: folder ?? 'visual_central/esp32',
          resourceType: CloudinaryResourceType.Image,
          publicId: publicId,
        ),
      );
      
      debugPrint('✅ Imagen subida a Cloudinary: ${response.secureUrl}');
      return response.secureUrl;
      
    } catch (e) {
      debugPrint('❌ Error subiendo bytes a Cloudinary: $e');
      return null;
    } finally {
      // Limpiar archivo temporal
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
  
  // Obtener URL optimizada
  String getOptimizedFaceUrl(String originalUrl, {int width = 300, int height = 300}) {
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/c_thumb,w_$width,h_$height,g_face/',
    );
  }
}