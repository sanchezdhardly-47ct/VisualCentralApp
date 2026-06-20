import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserData(user.uid);
      }
      notifyListeners();
    });
  }
  
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(uid).get();
      _userData = doc.data();
    } catch (e) {
      debugPrint('Error cargando datos de usuario: $e');
      _userData = null;
    }
  }
  
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);
      
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(), 
        password: password.trim(),
      );
      
      return result.user;
      
    } on FirebaseAuthException catch (e) {
      String mensaje;
      switch (e.code) {
        case 'user-not-found':
          mensaje = 'No existe usuario con este email';
          break;
        case 'wrong-password':
          mensaje = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          mensaje = 'Email inválido';
          break;
        case 'user-disabled':
          mensaje = 'Usuario deshabilitado';
          break;
        case 'too-many-requests':
          mensaje = 'Demasiados intentos. Intenta más tarde';
          break;
        default:
          mensaje = 'Error al iniciar sesión: ${e.code}';
      }
      throw Exception(mensaje);
      
    } catch (e) {
      debugPrint('Error en login: $e');
      throw Exception('Error de conexión');
      
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> verificarAccesoBiometrico(String userId) async {
    try {
      final userDoc = await _firestore.collection('usuarios').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data()!;
      final intentosFallidos = userData['intentosFallidos'] ?? 0;
      final maxIntentos = await _getMaxIntentos();
      
      if (intentosFallidos >= maxIntentos) {
        throw Exception('Usuario bloqueado por demasiados intentos');
      }
      
      return userData['datosBiometricos']?['rostroRegistrado'] ?? false;
      
    } catch (e) {
      debugPrint('Error verificando acceso: $e');
      return false;
    }
  }
  
  Future<int> _getMaxIntentos() async {
    try {
      final configDoc = await _firestore.collection('configuracion').doc('general').get();
      return configDoc.data()?['intentosMaximos'] ?? 3;
    } catch (e) {
      return 3;
    }
  }
  
  Future<void> registrarAcceso(String userId, bool exitoso) async {
    try {
      await _firestore.collection('logs_acceso').add({
        'userId': userId,
        'fecha': FieldValue.serverTimestamp(),
        'tipoAcceso': 'biometrico',
        'resultado': exitoso ? 'exitoso' : 'fallido',
      });
      
      if (!exitoso) {
        await _firestore.collection('usuarios').doc(userId).update({
          'intentosFallidos': FieldValue.increment(1),
        });
      } else {
        await _firestore.collection('usuarios').doc(userId).update({
          'intentosFallidos': 0,
          'ultimoAcceso': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error registrando acceso: $e');
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userData = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
