import 'package:cloud_firestore/cloud_firestore.dart';

class Acceso {
  final String id;
  final String usuarioId;
  final String usuarioNombre;
  final String tipo;
  final DateTime timestamp;
  final double precision;
  final bool exitoso;
  final String fotoEvidencia;

  Acceso({
    required this.id,
    required this.usuarioId,
    required this.usuarioNombre,
    required this.tipo,
    required this.timestamp,
    required this.precision,
    required this.exitoso,
    required this.fotoEvidencia,
  });

  factory Acceso.fromFirestore(Map<String, dynamic> data, String id) {
    return Acceso(
      id: id,
      usuarioId: data['usuarioId'] ?? '',
      usuarioNombre: data['usuarioNombre'] ?? 'Desconocido',
      tipo: data['tipo'] ?? 'denegado',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      precision: (data['precision'] ?? 0.0).toDouble(),
      exitoso: data['resultado']?['exitoso'] ?? false,
      fotoEvidencia: data['fotoEvidencia'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'usuarioNombre': usuarioNombre,
      'tipo': tipo,
      'timestamp': Timestamp.fromDate(timestamp),
      'precision': precision,
      'resultado': {
        'exitoso': exitoso,
      },
      'fotoEvidencia': fotoEvidencia,
    };
  }
}