import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'usuario.dart';
import 'acceso.dart';
import 'alerta.dart';

class DashboardProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Estado del sistema
  double _precisionSistema = 98.7;
  int _totalPersonal = 0;
  int _nuevosHoy = 0;
  int _totalRegistrosHoy = 0;
  int _alertasCriticas = 0;
  int _usuariosConRostro = 0;
  int _usuariosConHuella = 0;
  
  // Datos en tiempo real
  Acceso? _ultimoAcceso;
  List<Acceso> _accesosVerificados = [];
  List<Acceso> _accesosDenegados = [];
  List<Alerta> _alertas = [];
  List<Usuario> _usuariosRecientes = [];

  // Getters
  double get precisionSistema => _precisionSistema;
  int get totalPersonal => _totalPersonal;
  int get nuevosHoy => _nuevosHoy;
  int get totalRegistrosHoy => _totalRegistrosHoy;
  int get alertasCriticas => _alertasCriticas;
  int get usuariosConRostro => _usuariosConRostro;
  int get usuariosConHuella => _usuariosConHuella;
  Acceso? get ultimoAcceso => _ultimoAcceso;
  List<Acceso> get accesosVerificados => _accesosVerificados;
  List<Acceso> get accesosDenegados => _accesosDenegados;
  List<Alerta> get alertas => _alertas;
  List<Usuario> get usuariosRecientes => _usuariosRecientes;

  DashboardProvider() {
    _iniciarStreams();
    _cargarDatosIniciales();
  }

  void _iniciarStreams() {
    // Stream para últimos accesos
    _firestore
        .collection('accesos')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      _procesarAccesos(snapshot.docs);
    });

    // Stream para estadísticas en tiempo real
    _firestore
        .collection('accesos')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(hours: 24)))
        .snapshots()
        .listen((snapshot) {
      _totalRegistrosHoy = snapshot.docs.length;
      notifyListeners();
    });

    // Stream para alertas activas
    _firestore
        .collection('alertas')
        .where('estado', isEqualTo: 'activa')
        .snapshots()
        .listen((snapshot) {
      _alertas = snapshot.docs
          .map((doc) => Alerta.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      _alertasCriticas = _alertas.where((a) => a.tipo == 'critica').length;
      notifyListeners();
    });

    // Stream para usuarios recientes
    _firestore
        .collection('usuarios')
        .orderBy('metadata.fechaCreacion', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      _usuariosRecientes = snapshot.docs
          .map((doc) => Usuario.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    });
  }

  void _procesarAccesos(List<QueryDocumentSnapshot> docs) {
    List<Acceso> accesos = docs
        .map((doc) => Acceso.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    if (accesos.isNotEmpty) {
      _ultimoAcceso = accesos.first;
    }

    _accesosVerificados = accesos
        .where((a) => a.exitoso)
        .take(3)
        .toList();

    _accesosDenegados = accesos
        .where((a) => !a.exitoso)
        .take(3)
        .toList();

    notifyListeners();
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      await Future.wait([
        _cargarTotalPersonal(),
        _cargarNuevosHoy(),
        _cargarConfiguracion(),
        _cargarEstadisticasBiometricas(),
      ]);
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando datos iniciales: $e');
    }
  }

  Future<void> _cargarTotalPersonal() async {
    try {
      final personalSnapshot = await _firestore
          .collection('usuarios')
          .where('estado', isEqualTo: 'activo')
          .count()
          .get();
      _totalPersonal = personalSnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error cargando total personal: $e');
      _totalPersonal = 0;
    }
  }

  Future<void> _cargarNuevosHoy() async {
    try {
      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
      
      final nuevosSnapshot = await _firestore
          .collection('usuarios')
          .where('metadata.fechaCreacion', isGreaterThan: inicioDia)
          .count()
          .get();
      _nuevosHoy = nuevosSnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error cargando nuevos hoy: $e');
      _nuevosHoy = 0;
    }
  }

  Future<void> _cargarConfiguracion() async {
    try {
      final configDoc = await _firestore.collection('configuracion').doc('general').get();
      if (configDoc.exists) {
        _precisionSistema = (configDoc.data()?['precisionSistema'] ?? 98.7).toDouble();
      }
    } catch (e) {
      debugPrint('Error cargando configuración: $e');
    }
  }

  Future<void> _cargarEstadisticasBiometricas() async {
    try {
      final snapshot = await _firestore.collection('usuarios').get();
      int conRostro = 0;
      int conHuella = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final bio = data['datosBiometricos'] as Map<String, dynamic>?;
        if (bio != null) {
          if (bio['rostroRegistrado'] == true) conRostro++;
          if (bio['huellaRegistrada'] == true) conHuella++;
        }
      }
      
      _usuariosConRostro = conRostro;
      _usuariosConHuella = conHuella;
    } catch (e) {
      debugPrint('Error cargando estadísticas biométricas: $e');
      _usuariosConRostro = 0;
      _usuariosConHuella = 0;
    }
  }

  // Función para registrar nuevo acceso (desde la cámara)
  Future<void> registrarAcceso({
    required String usuarioId,
    required String usuarioNombre,
    required double precision,
    required bool exitoso,
    String? motivo,
    String? fotoEvidencia,
  }) async {
    try {
      final acceso = {
        'usuarioId': usuarioId,
        'usuarioNombre': usuarioNombre,
        'tipo': exitoso ? 'reconocido' : 'denegado',
        'timestamp': FieldValue.serverTimestamp(),
        'precision': precision,
        'resultado': {
          'exitoso': exitoso,
          'motivo': motivo,
          'duracion': 1.5,
        },
        'ubicacion': {
          'camaraId': 'CAM-01',
          'lugar': 'Acceso Principal',
        },
        'fotoEvidencia': fotoEvidencia ?? '',
      };

      await _firestore.collection('accesos').add(acceso);

      // Actualizar estadísticas del usuario
      if (exitoso) {
        await _firestore.collection('usuarios').doc(usuarioId).update({
          'ultimoAcceso': FieldValue.serverTimestamp(),
          'intentosFallidos': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('usuarios').doc(usuarioId).update({
          'intentosFallidos': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Si es denegado, crear alerta
      if (!exitoso) {
        await _crearAlerta(usuarioNombre, precision, motivo);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error registrando acceso: $e');
      rethrow;
    }
  }

  Future<void> _crearAlerta(String usuarioNombre, double precision, String? motivo) async {
    try {
      final alerta = {
        'tipo': 'critica',
        'timestamp': FieldValue.serverTimestamp(),
        'titulo': 'Intento de acceso no autorizado',
        'descripcion': motivo ?? 'Persona desconocida intentó acceder',
        'estado': 'activa',
        'metadata': {
          'precision': precision,
          'usuarioIntentado': usuarioNombre,
          'ubicacion': 'Acceso Principal',
        }
      };

      await _firestore.collection('alertas').add(alerta);
    } catch (e) {
      debugPrint('Error creando alerta: $e');
    }
  }

  // Función para actualizar datos manualmente
  Future<void> recargarDatos() async {
    await _cargarDatosIniciales();
    notifyListeners();
  }

  // Función para obtener estadísticas diarias
  Future<Map<String, dynamic>> getEstadisticasDiarias(DateTime fecha) async {
    try {
      final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDia = inicioDia.add(const Duration(days: 1));
      
      final accesosSnapshot = await _firestore
          .collection('accesos')
          .where('timestamp', isGreaterThanOrEqualTo: inicioDia)
          .where('timestamp', isLessThan: finDia)
          .get();
      
      int exitosos = 0;
      int denegados = 0;
      
      for (var doc in accesosSnapshot.docs) {
        final data = doc.data();
        final resultado = data['resultado'] as Map<String, dynamic>?;
        if (resultado?['exitoso'] == true) {
          exitosos++;
        } else {
          denegados++;
        }
      }
      
      return {
        'total': accesosSnapshot.docs.length,
        'exitosos': exitosos,
        'denegados': denegados,
        'tasaExito': accesosSnapshot.docs.isEmpty ? 0 : (exitosos / accesosSnapshot.docs.length) * 100,
      };
    } catch (e) {
      debugPrint('Error obteniendo estadísticas diarias: $e');
      return {
        'total': 0,
        'exitosos': 0,
        'denegados': 0,
        'tasaExito': 0,
      };
    }
  }

  // Función para obtener los últimos accesos de un usuario
  Future<List<Acceso>> getAccesosUsuario(String usuarioId) async {
    try {
      final snapshot = await _firestore
          .collection('accesos')
          .where('usuarioId', isEqualTo: usuarioId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      
      return snapshot.docs
          .map((doc) => Acceso.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo accesos del usuario: $e');
      return [];
    }
  }
}