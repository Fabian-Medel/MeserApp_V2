import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'qr.dart';

class Mesas extends StatelessWidget {
  final String restauranteId;
  final String nombreRestaurante;

  const Mesas({
    super.key,
    required this.restauranteId,
    required this.nombreRestaurante,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mesas - $nombreRestaurante')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(restauranteId)
            .collection('mesas')
            .orderBy('numero')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Cargando mesas o local sin mesas configuradas.'),
            );
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final mesa = docs[index].data() as Map<String, dynamic>;
              int numeroMesa = mesa['numero'];
              int estado = mesa['estado'] ?? 0;

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
                              numeroMesa: numeroMesa,
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
                        'Mesa $numeroMesa',
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