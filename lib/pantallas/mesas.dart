import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'qr.dart';

class Mesas extends StatelessWidget {
  const Mesas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Mesa')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurantes')
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay restaurantes disponibles.'),
            );
          }

          final docRestaurante = snapshot.data!.docs.first;
          final data = docRestaurante.data() as Map<String, dynamic>;
          // Guardamos el ID del documento para pasarlo
          final String restauranteId = docRestaurante.id;

          if (data['mesas'] == null) {
            return const Center(child: Text('Cargando mesas...'));
          }

          List<dynamic> mesasFirebase = data['mesas'];

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: mesasFirebase.length,
            itemBuilder: (context, index) {
              int estado = mesasFirebase[index];
              Color colorMesa = estado == 0
                  ? Colors.green
                  : (estado == 1 ? Colors.red : Colors.orange);
              String textoMesa = estado == 0
                  ? 'Libre'
                  : (estado == 1 ? 'Ocupada' : 'Limpiando');

              return GestureDetector(
                onTap: estado == 0
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LectorQR(
                              indexMesa: index,
                              idRestauranteDetectado: restauranteId,
                            ),
                          ),
                        );
                      }
                    : null,
                child: Card(
                  color: colorMesa,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mesa ${index + 1}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        estado == 0
                            ? Icons.check_circle
                            : (estado == 1
                                  ? Icons.cancel
                                  : Icons.cleaning_services),
                        color: Colors.white,
                        size: 40,
                      ),
                      Text(
                        textoMesa,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
