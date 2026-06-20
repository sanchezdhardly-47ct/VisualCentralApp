import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';  // 👈 NUEVA IMPORTACIÓN

import 'custom_auth_provider.dart';
import 'dashboard_provider.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null);
  
  // INICIALIZAR FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // CREAR DATOS INICIALES AUTOMÁTICAMENTE
  await _crearDatosIniciales();
  
  runApp(const MyApp());
}

Future<void> _crearDatosIniciales() async {
  print('🔄 Verificando datos iniciales...');
  
  try {
    // 1. CREAR USUARIO ADMIN EN AUTHENTICATION
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: "admin@visualcentral.com",
        password: "123456",
      );
      print('✅ Usuario admin creado en Authentication');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('ℹ️ Usuario admin ya existe');
      }
    }
    
    // 2. CREAR CONFIGURACIÓN
    final configRef = FirebaseFirestore.instance
        .collection('configuracion')
        .doc('general');
    
    final configDoc = await configRef.get();
    if (!configDoc.exists) {
      await configRef.set({
        'intentosMaximos': 3,
        'umbralReconocimiento': 0.85,
        'tiempoSesion': 480,
        'precisionSistema': 98.7,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Configuración creada');
    }
    
    // 3. CREAR USUARIO ADMIN EN FIRESTORE
    final userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc('admin');
    
    final userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'nombre': 'Administrador',
        'email': 'admin@visualcentral.com',
        'rol': 'admin',
        'departamento': 'IT',
        'cargo': 'Administrador del Sistema',
        'estado': 'activo',
        'intentosFallidos': 0,
        'datosBiometricos': {
          'rostroRegistrado': true,
          'huellaRegistrada': true,
        },
        'metadata': {
          'creadoPor': 'sistema',
          'fechaCreacion': FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Usuario admin creado en Firestore');
    }
    
    print('🎉 Datos iniciales verificados');
  } catch (e) {
    print('❌ Error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomAuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'Visual Central',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}