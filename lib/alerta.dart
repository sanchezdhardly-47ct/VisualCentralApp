import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Alerta {
  final String id;
  final String tipo;
  final DateTime timestamp;
  final String titulo;
  final String descripcion;
  final String estado;

  Alerta({
    required this.id,
    required this.tipo,
    required this.timestamp,
    required this.titulo,
    required this.descripcion,
    required this.estado,
  });

  factory Alerta.fromFirestore(Map<String, dynamic> data, String id) {
    return Alerta(
      id: id,
      tipo: data['tipo'] ?? 'info',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      estado: data['estado'] ?? 'activa',
    );
  }
  
  Color get color {
    switch (tipo) {
      case 'critica':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
