import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GestionMenu extends StatefulWidget {
  const GestionMenu({super.key});

  @override
  State<GestionMenu> createState() => _GestionMenuState();
}

class _GestionMenuState extends State<GestionMenu> {
  final User? usuario = FirebaseAuth.instance.currentUser;
  final _nombreCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  bool _subiendo = false;

  void _abrirFormulario({String? id, String? nombre, int? precio}) {
    _nombreCtrl.text = nombre ?? '';
    _precioCtrl.text = precio?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(id == null ? 'Nuevo Plato' : 'Editar Plato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del plato',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _precioCtrl,
                decoration: const InputDecoration(labelText: 'Precio (\$)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _subiendo ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _subiendo
                  ? null
                  : () async {
                      setStateDialog(() => _subiendo = true);
                      await _guardarPlato(id);
                      setStateDialog(() => _subiendo = false);
                    },
              child: _subiendo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarPlato(String? id) async {
    final String nombre = _nombreCtrl.text.trim();
    final int? precio = int.tryParse(_precioCtrl.text.trim());

    if (nombre.isEmpty || precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valores no válidos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final ref = FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(usuario!.uid)
          .collection('platos');

      if (id == null) {
        await ref.add({'nombre': nombre, 'precio': precio});
      } else {
        await ref.doc(id).update({'nombre': nombre, 'precio': precio});
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _eliminarPlato(String id) async {
    await FirebaseFirestore.instance
        .collection('restaurantes')
        .doc(usuario!.uid)
        .collection('platos')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestionar Platos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(usuario?.uid)
            .collection('platos')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text('No hay platos registrados.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    data['nombre'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('\$${data['precio']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _abrirFormulario(
                          id: doc.id,
                          nombre: data['nombre'],
                          precio: data['precio'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _eliminarPlato(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormulario(),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
