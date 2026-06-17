import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mesas.dart';
import 'qr.dart';
import '../features/assistant/presentation/chat_screen.dart';

class SeleccionRestaurante extends StatelessWidget {
  const SeleccionRestaurante({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un Restaurante'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurantes')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay restaurantes registrados aún.'),
            );
          }

          final restaurantes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: restaurantes.length,
            itemBuilder: (context, index) {
              final res = restaurantes[index];
              final data = res.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.store, color: Colors.white),
                  ),
                  title: Text(
                    data['nombre'] ?? 'Restaurante sin nombre',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    data['direccion'] ?? 'Dirección no disponible',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Mesas(
                          restauranteId: res.id,
                          nombreRestaurante: data['nombre'] ?? 'Restaurante',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            height: 70,
            child: FloatingActionButton.extended(
              heroTag: 'btn_sofia',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                );
              },
              backgroundColor: Colors.indigo,
              elevation: 8,
              icon: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Image.asset('assets/images/sofia.png', fit: BoxFit.contain),
                ),
              ),
              label: const Text(
                'SofIA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          FloatingActionButton.extended(
            heroTag: 'btn_qr',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LectorQR()),
              );
            },
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear Mesa'),
          ),
        ],
      ),
    );
  }
}
