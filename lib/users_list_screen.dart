import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_user_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  String _searchQuery = '';
  String _filterRol = 'todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios del Sistema'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddUserScreen()),
              ).then((_) {
                setState(() {});
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar usuario...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', 'todos'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Empleados', 'empleado'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Administradores', 'admin'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Activos', 'activo'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactivos', 'inactivo'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de usuarios
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .orderBy('metadata.fechaCreacion', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                var users = snapshot.data!.docs;
                
                // Aplicar filtros
                users = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nombre = (data['nombre'] ?? '').toLowerCase();
                  final email = (data['email'] ?? '').toLowerCase();
                  final rol = data['rol'] ?? 'empleado';
                  final estado = data['estado'] ?? 'activo';
                  
                  // Filtro por búsqueda
                  if (_searchQuery.isNotEmpty &&
                      !nombre.contains(_searchQuery) &&
                      !email.contains(_searchQuery)) {
                    return false;
                  }
                  
                  // Filtro por rol/estado
                  if (_filterRol == 'empleado' && rol != 'empleado') return false;
                  if (_filterRol == 'admin' && rol != 'admin') return false;
                  if (_filterRol == 'activo' && estado != 'activo') return false;
                  if (_filterRol == 'inactivo' && estado != 'inactivo') return false;
                  
                  return true;
                }).toList();
                
                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No hay usuarios registrados',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddUserScreen()),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Usuario'),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bio = data['datosBiometricos'] as Map<String, dynamic>?;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: data['rol'] == 'admin' 
                              ? Colors.red.shade100 
                              : Colors.blue.shade100,
                          child: Icon(
                            data['rol'] == 'admin' ? Icons.admin_panel_settings : Icons.person,
                            color: data['rol'] == 'admin' ? Colors.red : Colors.blue,
                          ),
                        ),
                        title: Text(
                          data['nombre'] ?? 'Sin nombre',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['email'] ?? 'Sin email'),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (bio?['rostroRegistrado'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '✓ Rostro',
                                      style: TextStyle(fontSize: 10, color: Colors.green),
                                    ),
                                  ),
                                if (bio?['huellaRegistrada'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '✓ Huella',
                                      style: TextStyle(fontSize: 10, color: Colors.blue),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: data['estado'] == 'activo' 
                                        ? Colors.green.shade100 
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    data['estado'] ?? 'activo',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: data['estado'] == 'activo' ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(Icons.block, size: 20),
                                  SizedBox(width: 8),
                                  Text('Cambiar estado'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await _confirmarEliminar(doc.id, data['nombre']);
                            } else if (value == 'toggle') {
                              await _toggleEstado(doc.id, data['estado'] ?? 'activo');
                            } else if (value == 'edit') {
                              // Navegar a edición
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddUserScreen()),
          ).then((_) {
            setState(() {});
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _filterRol == value,
      onSelected: (selected) {
        setState(() {
          _filterRol = selected ? value : 'todos';
        });
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue,
    );
  }
  
  Future<void> _confirmarEliminar(String userId, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de eliminar a $nombre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('usuarios').doc(userId).delete();
        // También eliminar de Auth si es necesario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _toggleEstado(String userId, String estadoActual) async {
    final nuevoEstado = estadoActual == 'activo' ? 'inactivo' : 'activo';
    
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(userId).update({
        'estado': nuevoEstado,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuario ${nuevoEstado == 'activo' ? 'activado' : 'desactivado'}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}