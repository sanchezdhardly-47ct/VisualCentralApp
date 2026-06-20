import 'package:flutter/material.dart';
import 'acceso.dart';

class LiveFeedCard extends StatelessWidget {
  final Acceso? ultimoAcceso;
  final List<Acceso> accesosVerificados;
  final List<Acceso> accesosDenegados;

  const LiveFeedCard({
    super.key,
    this.ultimoAcceso,
    required this.accesosVerificados,
    required this.accesosDenegados,
  });

  @override
  Widget build(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Últimos Registros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Live Feed Item
          if (ultimoAcceso != null) ...[
            _buildFeedItem(
              nombre: ultimoAcceso!.usuarioNombre,
              hora: _formatHora(ultimoAcceso!.timestamp),
              esReconocido: ultimoAcceso!.exitoso,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Verificados
          const Text(
            'Eventos de Hoy',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          const Text(
            'Verificados',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          ...accesosVerificados.map((acceso) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  acceso.usuarioNombre,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _formatHora(acceso.timestamp),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 12),
          
          const Text(
            'Denegados',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          ...accesosDenegados.map((acceso) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 desconocido',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  _formatHora(acceso.timestamp),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFeedItem({
    required String nombre,
    required String hora,
    required bool esReconocido,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: esReconocido ? Colors.green : Colors.red,
            radius: 20,
            child: Icon(
              esReconocido ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esReconocido ? 'Reconocido:' : 'Denegado:',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            hora,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatHora(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : hour;
    return '${hour12.toString().padLeft(2, '0')}:$minute $ampm';
  }
}