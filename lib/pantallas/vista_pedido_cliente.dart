import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../estado/app_state.dart';
import 'menu.dart';
import 'inicio.dart';

class VistaPedidoCliente extends StatelessWidget {
  const VistaPedidoCliente({super.key});

  void _mostrarConfirmacionAsistencia(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Solicitar Asistencia?'),
        content: const Text(
          'Llamaremos a un mesero a tu mesa. Usa esta opción solo si requieres ayuda presencial o tienes alguna duda con el menú.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              appState.solicitarAsistencia();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Un mesero va en camino...'),
                  backgroundColor: Colors.indigo,
                ),
              );
            },
            child: const Text(
              'Llamar Mesero',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (appState.mesaSeleccionada == null) {
      return const Scaffold(body: Center(child: Text("Sin mesa activa")));
    }

    int numeroMesa = appState.mesaSeleccionada!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No puedes retroceder. Usa el botón "Retirarse de la mesa" al terminar.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mesa $numeroMesa - Tus Pedidos'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            if (appState.restauranteId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('restaurantes')
                    .doc(appState.restauranteId)
                    .collection('notificaciones')
                    .where('mesa', isEqualTo: numeroMesa)
                    .where('estado', whereIn: ['pendiente', 'en_proceso'])
                    .snapshots(),
                builder: (context, snapshot) {
                  bool ocupado =
                      snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  return IconButton(
                    icon: Icon(
                      Icons.room_service,
                      color: ocupado ? Colors.white30 : Colors.white,
                    ),
                    tooltip: ocupado
                        ? 'Mesero en camino'
                        : 'Solicitar Asistencia',
                    onPressed: ocupado
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Un mesero ya está en camino a tu mesa.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        : () => _mostrarConfirmacionAsistencia(context),
                  );
                },
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('restaurantes')
                    .doc(appState.restauranteId)
                    .collection('pedidos')
                    .where('mesa', isEqualTo: numeroMesa)
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pedidosActivos = snapshot.data!.docs.where((doc) {
                    return (doc.data() as Map<String, dynamic>)['estado'] !=
                        'archivado';
                  }).toList();

                  if (pedidosActivos.isEmpty) {
                    return const Center(
                      child: Text('No hay pedidos activos en esta mesa.'),
                    );
                  }

                  bool todosEntregados = pedidosActivos.every((doc) {
                    final estado =
                        (doc.data() as Map<String, dynamic>)['estado']
                            .toString()
                            .toUpperCase();
                    return estado == 'ENTREGADO';
                  });

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: pedidosActivos.length,
                          itemBuilder: (context, index) {
                            final doc = pedidosActivos[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final items = data['pedido'] as List<dynamic>;

                            String estado = data['estado']
                                .toString()
                                .toUpperCase();
                            Color colorEstado = Colors.grey;
                            if (estado == 'ESPERANDO_PAGO') {
                              colorEstado = Colors.redAccent;
                            }
                            if (estado == 'PREPARANDO' || estado == 'PENDIENTE') {
                              colorEstado = Colors.orange;
                            }
                            if (estado == 'LISTO') colorEstado = Colors.blue;
                            if (estado == 'ENTREGADO') {
                              colorEstado = Colors.green;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              elevation: 3,
                              child: ExpansionTile(
                                initiallyExpanded: true,
                                title: Text(
                                  'Pedido ${index + 1} - Total: \$${data['total']}',
                                ),
                                subtitle: Text(
                                  'Estado: $estado',
                                  style: TextStyle(
                                    color: colorEstado,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                children: items.map((item) {
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.fastfood,
                                      size: 20,
                                    ),
                                    title: Text(item['nombre']),
                                    trailing: Text('x${item['cantidad']}'),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.grey.shade100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text(
                                'Pedir más comida',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const Menu(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text(
                                'Retirarse de la mesa',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: todosEntregados
                                    ? Colors.red.shade700
                                    : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              onPressed: () {
                                if (!todosEntregados) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Aún tienes pedidos en proceso o sin entregar.',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('¿Finalizar visita?'),
                                    content: const Text(
                                      'Se llamará al equipo de limpieza para preparar la mesa.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () {
                                          appState.solicitarLimpieza();
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const Inicio(),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                        child: const Text(
                                          'Confirmar Salida',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
