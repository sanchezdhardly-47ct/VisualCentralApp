// esp32_endpoint.dart
// Esto sería para un servidor aparte o Firebase Functions

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> handleESP32Upload(Map<String, dynamic> data) async {
  try {
    await FirebaseFirestore.instance.collection('accesos_esp32').add({
      'imageUrl': data['imageUrl'],
      'deviceId': data['deviceId'] ?? 'ESP32-01',
      'timestamp': FieldValue.serverTimestamp(),
      'procesado': false,
    });
    
    print('✅ Registro guardado en Firestore');
  } catch (e) {
    print('❌ Error: $e');
  }
}