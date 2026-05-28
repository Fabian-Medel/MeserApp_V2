import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../estado/app_state.dart';
import 'carrito.dart';
import 'detalle_plato.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appState.mesaSeleccionada != null
              ? 'Menú - Mesa ${appState.mesaSeleccionada! + 1}'
              : 'Consulta de Menú',
        ),
        automaticallyImplyLeading: appState.mesaSeleccionada != null
            ? false
            : true,
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.restauranteId == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.indigo),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('restaurantes')
                .doc(appState.restauranteId)
                .collection('platos')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError || !snapshot.hasData)
                return const Center(child: Text('Error al cargar.'));
              final platos = snapshot.data!.docs;
              if (platos.isEmpty)
                return const Center(child: Text('Menú vacío.'));

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: platos.length,
                itemBuilder: (context, index) {
                  final item = platos[index].data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetallePlato(plato: item),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Image.network(
                              item['urlImagen'] ??
                                  'https://via.placeholder.com/400x200',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 15,
                              left: 15,
                              right: 15,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nombre'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${item['tiempo'] ?? '20'} minutos',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '\$${item['precio']}',
                                          style: const TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: appState.mesaSeleccionada != null
          ? FloatingActionButton(
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
            )
          : null,
      bottomNavigationBar: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.carrito.isEmpty || appState.mesaSeleccionada == null)
            return const SizedBox.shrink();
          return BottomAppBar(
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Carrito()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: Text('Ver Carrito (\$${appState.totalCarrito})'),
            ),
          );
        },
      ),
    );
  }
}
