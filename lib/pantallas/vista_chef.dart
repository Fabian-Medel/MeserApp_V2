import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../estado/app_state.dart';

class VistaChef extends StatelessWidget {
  const VistaChef({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cocina - Pedidos Pendientes',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange.shade800,
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.restauranteId == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('restaurantes')
                .doc(appState.restauranteId)
                .collection('pedidos')
                .where('estado', isEqualTo: 'pendiente')
                .orderBy('timestamp', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.soup_kitchen, size: 80, color: Colors.grey),
                      SizedBox(height: 15),
                      Text(
                        'No hay pedidos pendientes',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final pedidos = snapshot.data!.docs;

              return ListView.builder(
                itemCount: pedidos.length,
                itemBuilder: (context, index) {
                  final doc = pedidos[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final items = data['pedido'] as List<dynamic>;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'MESA ${data['mesa']}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              const Chip(
                                label: Text(
                                  'PENDIENTE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            ],
                          ),
                          const Divider(thickness: 1.5),
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.restaurant,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${item['cantidad']}x ${item['nombre']}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  doc.reference.update({'estado': 'listo'}),
                              icon: const Icon(Icons.check_circle),
                              label: const Text(
                                '¡Pedido Listo!',
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
