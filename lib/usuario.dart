import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String departamento;
  final String estado;
  final DateTime? ultimoAcceso;
  final double precisionPromedio;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.departamento,
    required this.estado,
    this.ultimoAcceso,
    required this.precisionPromedio,
  });

  factory Usuario.fromFirestore(Map<String, dynamic> data, String id) {
    return Usuario(
      id: id,
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      rol: data['rol'] ?? 'empleado',
      departamento: data['departamento'] ?? '',
      estado: data['estado'] ?? 'activo',
      ultimoAcceso: (data['ultimoAcceso'] as Timestamp?)?.toDate(),
      precisionPromedio: (data['datosBiometricos']?['precisionPromedio'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'departamento': departamento,
      'estado': estado,
      'ultimoAcceso': ultimoAcceso != null ? Timestamp.fromDate(ultimoAcceso!) : null,
      'datosBiometricos': {
        'precisionPromedio': precisionPromedio,
      },
    };
  }
}
