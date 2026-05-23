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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.indigo),
                  SizedBox(height: 15),
                  Text(
                    'Cargando la carta...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('restaurantes')
                .doc(appState.restauranteId)
                .collection('platos')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.indigo),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(child: Text('Error al cargar el menú.'));
              }

              final platos = snapshot.data!.docs;

              if (platos.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Este restaurante aún no ha publicado su menú.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 30),
                itemCount: platos.length,
                itemBuilder: (context, index) {
                  final platoDoc = platos[index];
                  final item = platoDoc.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetallePlato(plato: item),
                        ),
                      );
                    },
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
                            Hero(
                              tag: item['nombre'],
                              child: Image.network(
                                item['urlImagen'] ??
                                    'https://via.placeholder.com/400x200',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.restaurant,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                              ),
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
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            color: Colors.white70,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            item['tiempo'] ?? '20 min',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
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
