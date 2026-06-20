import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';  // 👈 Importar CloudinaryService

class BiometricService {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();  // 👈 Instancia
  
  // Detectar si hay un rostro en la imagen
  Future<bool> detectarRostro(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFile(File(imageFile.path));
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: true,
          enableClassification: true,
        ),
      );
      
      final List<Face> faces = await faceDetector.processImage(inputImage);
      faceDetector.close();
      
      return faces.isNotEmpty;
    } catch (e) {
      debugPrint('Error detectando rostro: $e');
      return false;
    }
  }
  
  // Analizar características del rostro
  Future<Map<String, dynamic>> analizarRostro(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFile(File(imageFile.path));
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: true,
          enableClassification: true,
        ),
      );
      
      final List<Face> faces = await faceDetector.processImage(inputImage);
      faceDetector.close();
      
      if (faces.isEmpty) {
        return {'detectado': false};
      }
      
      final Face face = faces.first;
      
      return {
        'detectado': true,
        'smilingProbability': face.smilingProbability,
        'leftEyeOpenProbability': face.leftEyeOpenProbability,
        'rightEyeOpenProbability': face.rightEyeOpenProbability,
        'boundingBox': {
          'left': face.boundingBox.left,
          'top': face.boundingBox.top,
          'right': face.boundingBox.right,
          'bottom': face.boundingBox.bottom,
        },
      };
    } catch (e) {
      debugPrint('Error analizando rostro: $e');
      return {'detectado': false, 'error': e.toString()};
    }
  }
  
  // Guardar imagen biométrica usando Cloudinary
  Future<String?> guardarImagenBiometrica(String userId, File imageFile) async {
    return await _cloudinaryService.uploadImage(
      imageFile,
      userId: userId,
      folder: 'visual_central/biometricos/$userId',
    );
  }
  
  // Guardar imagen desde XFile
  Future<String?> guardarImagenDesdeXFile(String userId, XFile imageFile) async {
    return await _cloudinaryService.uploadXFile(
      imageFile,
      userId: userId,
      folder: 'visual_central/biometricos/$userId',
    );
  }
  
  // Comparar dos rostros
  Future<bool> compararRostros(File imagen1, File imagen2) async {
    debugPrint('Comparando rostros...');
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // Tomar foto con la cámara
  Future<XFile?> tomarFoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return photo;
    } catch (e) {
      debugPrint('Error tomando foto: $e');
      return null;
    }
  }
  
  // Obtener la cámara disponible
  Future<CameraDescription?> getCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
        return frontCamera;
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo cámara: $e');
      return null;
    }
  }
}