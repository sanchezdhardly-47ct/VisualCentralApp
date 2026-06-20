import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_provider.dart';
import 'status_card.dart';
import 'live_feed_card.dart';
import 'users_list_screen.dart';
import 'add_user_screen.dart';
import 'usuario.dart';
import 'alerta.dart';
import 'face_verification_screen.dart'; // 👈 IMPORTANTE: Agregar este import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late DashboardProvider _provider;

  // 👈 IP del ESP32 (CÁMBIALA POR LA IP REAL DE TU DISPOSITIVO)
  final String _esp32Ip = '192.168.1.100';

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<DashboardProvider>(context, listen: false);
    _provider.recargarDatos();
  }

  // 👈 MÉTODO PARA ABRIR LA VERIFICACIÓN FACIAL
  Future<void> _marcarEntrada() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceVerificationScreen(esp32Ip: _esp32Ip),
      ),
    );
    
    if (result == true && mounted) {
      // Refrescar datos si la verificación fue exitosa
      _provider.recargarDatos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Acceso registrado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.visibility, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            const Text(
              'VISUAL CENTRAL',
              style: TextStyle(
                color: Color(0xFF424242),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                _mostrarMenuPerfil();
              },
              child: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person, color: Colors.blue),
                radius: 20,
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardView(),
          const UsersListScreen(),
          const AddUserScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade400,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          
          if (index == 1 || index == 2) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_selectedIndex == 0) {
                _provider.recargarDatos();
              }
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Añadir',
          ),
        ],
      ),
      // 👈 BOTÓN FLOTANTE PARA MARCAR ENTRADA
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _marcarEntrada,
        icon: const Icon(Icons.login),
        label: const Text('Marcar Entrada'),
        backgroundColor: Colors.green,
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildDashboardView() {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () => provider.recargarDatos(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saludo con fecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hola, Administrador',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat("EEEE, d 'de' MMMM", 'es_ES').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sistema Online',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Estado del Sistema
                StatusCard(
                  titulo: 'Biométrico Facial',
                  estado: 'ACTIVO Y OPERATIVO',
                  precision: provider.precisionSistema,
                ),
                const SizedBox(height: 16),

                // Grid de métricas principales
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        titulo: 'Personal Total',
                        valor: provider.totalPersonal.toString(),
                        subtitulo: '+${provider.nuevosHoy} hoy',
                        icono: Icons.people,
                        color: Colors.purple,
                        onTap: () {
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        titulo: 'Registros Hoy',
                        valor: provider.totalRegistrosHoy.toString(),
                        subtitulo: 'accesos registrados',
                        icono: Icons.fingerprint,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Métricas biométricas
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        titulo: 'Rostros Registrados',
                        valor: provider.usuariosConRostro.toString(),
                        subtitulo: 'de ${provider.totalPersonal} usuarios',
                        icono: Icons.face,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        titulo: 'Huellas Registradas',
                        valor: provider.usuariosConHuella.toString(),
                        subtitulo: 'de ${provider.totalPersonal} usuarios',
                        icono: Icons.fingerprint,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Alertas
                _buildAlertasCard(provider),
                const SizedBox(height: 16),

                // Live Feed
                LiveFeedCard(
                  ultimoAcceso: provider.ultimoAcceso,
                  accesosVerificados: provider.accesosVerificados,
                  accesosDenegados: provider.accesosDenegados,
                ),
                const SizedBox(height: 16),

                // Usuarios recientes
                _buildUsuariosRecientesCard(provider),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icono,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                Icon(icono, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitulo,
              style: TextStyle(
                color: subtitulo.contains('hoy') ? Colors.green : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertasCard(DashboardProvider provider) {
    if (provider.alertas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade400),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No hay alertas activas',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text(
                'Alertas Activas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (provider.alertasCriticas > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.alertasCriticas} críticas',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...provider.alertas.take(3).map((alerta) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: alerta.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: alerta.color.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: alerta.color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alerta.titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: alerta.color,
                          ),
                        ),
                        Text(
                          alerta.descripcion,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(alerta.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )),
          if (provider.alertas.length > 3)
            TextButton(
              onPressed: () {
                _mostrarTodasAlertas(provider.alertas);
              },
              child: const Text('Ver todas las alertas'),
            ),
        ],
      ),
    );
  }

  Widget _buildUsuariosRecientesCard(DashboardProvider provider) {
    if (provider.usuariosRecientes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Text('No hay usuarios registrados'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usuarios Recientes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...provider.usuariosRecientes.map((usuario) => ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            title: Text(
              usuario.nombre,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(usuario.email),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: usuario.estado == 'activo' 
                    ? Colors.green.shade100 
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                usuario.estado == 'activo' ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: 10,
                  color: usuario.estado == 'activo' ? Colors.green : Colors.red,
                ),
              ),
            ),
            onTap: () {
              _mostrarDetallesUsuario(usuario);
            },
          )),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
            child: const Text('Ver todos los usuarios'),
          ),
        ],
      ),
    );
  }

  void _mostrarMenuPerfil() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Administrador',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'admin@visualcentral.com',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarConfiguracion();
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Ayuda'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarAyuda();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarCerrarSesion();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _mostrarTodasAlertas(List<Alerta> alertas) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Todas las Alertas'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: alertas.length,
            itemBuilder: (context, index) {
              final alerta = alertas[index];
              return ListTile(
                leading: Icon(Icons.notifications, color: alerta.color),
                title: Text(alerta.titulo),
                subtitle: Text(alerta.descripcion),
                trailing: Text(
                  DateFormat('HH:mm dd/MM').format(alerta.timestamp),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesUsuario(Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(usuario.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Email', usuario.email),
            _buildInfoRow('Rol', usuario.rol),
            _buildInfoRow('Departamento', usuario.departamento),
            _buildInfoRow('Estado', usuario.estado),
            _buildInfoRow('Precisión', '${usuario.precisionPromedio.toStringAsFixed(1)}%'),
            if (usuario.ultimoAcceso != null)
              _buildInfoRow('Último acceso', DateFormat('dd/MM/yyyy HH:mm').format(usuario.ultimoAcceso!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarConfiguracion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración - Próximamente disponible'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda'),
        content: const Text(
          'Visual Central - Sistema de Control de Acceso Biométrico\n\n'
          'Funcionalidades:\n'
          '• Dashboard: Visualiza estadísticas en tiempo real\n'
          '• Usuarios: Gestiona todos los usuarios registrados\n'
          '• Añadir: Registra nuevos usuarios con datos biométricos\n\n'
          'Para más información, contacta al administrador del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al cerrar sesión: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}