import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../estado/app_state.dart';
import 'menu.dart';

class VistaPedidoCliente extends StatelessWidget {
  const VistaPedidoCliente({super.key});

  @override
  Widget build(BuildContext context) {
    if (appState.mesaSeleccionada == null) {
      return const Scaffold(body: Center(child: Text("Sin mesa activa")));
    }

    int numeroMesa = appState.mesaSeleccionada! + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mesa $numeroMesa - Tus Pedidos'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
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
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final pedidosActivos = snapshot.data!.docs.where((doc) {
                  return (doc.data() as Map<String, dynamic>)['estado'] !=
                      'archivado';
                }).toList();

                pedidosActivos.sort((a, b) {
                  final tA = a.get('timestamp') as Timestamp?;
                  final tB = b.get('timestamp') as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tA.compareTo(tB);
                });

                if (pedidosActivos.isEmpty) {
                  return const Center(
                    child: Text('No hay pedidos activos en esta mesa.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: pedidosActivos.length,
                  itemBuilder: (context, index) {
                    final doc = pedidosActivos[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final items = data['pedido'] as List<dynamic>;

                    String estado = data['estado'].toString().toUpperCase();
                    Color colorEstado = Colors.grey;
                    if (estado == 'PREPARANDO' || estado == 'PENDIENTE')
                      colorEstado = Colors.orange;
                    if (estado == 'LISTO') colorEstado = Colors.blue;
                    if (estado == 'ENTREGADO') colorEstado = Colors.green;

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
                            leading: const Icon(Icons.fastfood, size: 20),
                            title: Text(item['nombre']),
                            trailing: Text('x${item['cantidad']}'),
                          );
                        }).toList(),
                      ),
                    );
                  },
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
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Menu()),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: const Text(
                    'Pedir la cuenta / Finalizar',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Finalizar visita?'),
                        content: const Text(
                          'Se llamará al mesero para darte la cuenta y se limpiará la mesa.',
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
                              Navigator.pop(context);
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          appState.solicitarAsistencia();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Un mesero va en camino...'),
              backgroundColor: Colors.indigo,
            ),
          );
        },
        backgroundColor: Colors.indigo,
        tooltip: 'Llamar Mesero',
        child: const Icon(Icons.room_service, color: Colors.white),
      ),
    );
  }
}
