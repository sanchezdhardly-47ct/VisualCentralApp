import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';

class FaceComparisonService {
  // Compara dos imágenes a partir de sus URLs
  // Retorna true si la similitud supera el umbral
  Future<bool> compareFaces(String storedImageUrl, String capturedImageUrl) async {
    try {
      // Descargar ambas imágenes
      final storedFile = await _downloadImage(storedImageUrl);
      final capturedFile = await _downloadImage(capturedImageUrl);
      
      // Extraer descriptores faciales (embeddings)
      final storedFeatures = await _extractFaceFeatures(storedFile);
      final capturedFeatures = await _extractFaceFeatures(capturedFile);
      
      if (storedFeatures == null || capturedFeatures == null) {
        print("No se detectaron rostros en una o ambas imágenes");
        return false;
      }
      
      // Calcular similitud (distancia euclidiana entre descriptores)
      final similarity = _calculateSimilarity(storedFeatures, capturedFeatures);
      print("Similitud: $similarity");
      
      // Umbral de similitud (ajustable)
      return similarity > 0.6; // 60% de similitud
      
    } catch (e) {
      print("Error comparando rostros: $e");
      return false;
    }
  }
  
  // Descarga una imagen y la guarda en un archivo temporal
  Future<File> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception("No se pudo descargar la imagen: $url");
    }
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
  
  // Extrae características faciales usando ML Kit
  Future<List<double>?> _extractFaceFeatures(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableContours: true,
        // Nota: ML Kit no provee embeddings directamente, esta es una simplificación.
        // En producción, se necesita un modelo de embeddings o un servicio como Firebase ML.
      ),
    );
    
    final faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();
    
    if (faces.isEmpty) return null;
    
    // Usamos las coordenadas de los landmarks como "características" (muy simplificado)
    // Idealmente usaríamos un modelo de embeddings como FaceNet.
    final face = faces.first;
    List<double> features = [];
    for (var landmark in face.landmarks.values) {
      features.add(landmark.position.dx);
      features.add(landmark.position.dy);
    }
    // Normalizar (simplificado)
    return features;
  }
  
  // Calcula la similitud del coseno o distancia euclidiana
  double _calculateSimilarity(List<double> features1, List<double> features2) {
    // Si los vectores no tienen la misma longitud, no se puede comparar
    if (features1.length != features2.length) return 0.0;
    
    // Distancia euclidiana
    double sum = 0.0;
    for (int i = 0; i < features1.length; i++) {
      sum += (features1[i] - features2[i]) * (features1[i] - features2[i]);
    }
    double distance = sum.sqrt();
    
    // Convertir distancia a similitud (asumiendo que distancia máxima posible es ~500)
    double similarity = 1.0 - (distance / 500.0);
    return similarity.clamp(0.0, 1.0);
  }
}