import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GestionMesas extends StatefulWidget {
  const GestionMesas({super.key});

  @override
  State<GestionMesas> createState() => _GestionMesasState();
}

class _GestionMesasState extends State<GestionMesas> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  int _calcularSiguienteMesa(List<int> numerosExistentes) {
    numerosExistentes.sort();
    int siguiente = 1;
    for (int num in numerosExistentes) {
      if (num == siguiente) {
        siguiente++;
      } else if (num > siguiente) {
        break;
      }
    }
    return siguiente;
  }

  void _crearMesa(List<int> actuales) async {
    int nuevoNumero = _calcularSiguienteMesa(actuales);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear Mesa $nuevoNumero'),
        content: Text('Se procederá a habilitar la Mesa número $nuevoNumero con un código QR único asignado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('restaurantes')
                  .doc(uid)
                  .collection('mesas')
                  .doc('$nuevoNumero')
                  .set({
                    'numero': nuevoNumero,
                    'estado': 0,
                    'id': '$nuevoNumero|$uid' 
                  });
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _eliminarMesa(int numeroMesa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar Mesa $numeroMesa?'),
        content: const Text('Esta acción es destructiva. Se removerá la mesa del panel y el código QR impreso dejará de ser válido de inmediato.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('restaurantes')
                  .doc(uid)
                  .collection('mesas')
                  .doc('$numeroMesa')
                  .delete();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _verQR(int numeroMesa, String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Código QR - Mesa $numeroMesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 10),
            Text('ID: $qrData', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Mesas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(uid)
            .collection('mesas')
            .orderBy('numero')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final mesa = docs[index].data() as Map<String, dynamic>;
              int numero = mesa['numero'];
              String qrData = mesa['id'] ?? '$numero|$uid';

              return Card(
                color: Colors.indigo.shade50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Mesa $numero', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(icon: const Icon(Icons.qr_code, color: Colors.black87), onPressed: () => _verQR(numero, qrData)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarMesa(numero)),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('restaurantes').doc(uid).collection('mesas').snapshots(),
        builder: (context, snapshot) {
          List<int> actuales = [];
          if (snapshot.hasData) {
            actuales = snapshot.data!.docs.map((d) => (d.data() as Map)['numero'] as int).toList();
          }
          return FloatingActionButton.extended(
            onPressed: () => _crearMesa(actuales),
            backgroundColor: Colors.indigo,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Crear Mesa', style: TextStyle(color: Colors.white)),
          );
        }
      ),
    );
  }
}