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
  final _descripcionCtrl = TextEditingController();
  final _tiempoCtrl = TextEditingController();
  final _urlImagenCtrl = TextEditingController();
  bool _subiendo = false;

  void _abrirFormulario({
    String? id,
    String? nombre,
    int? precio,
    String? descripcion,
    String? tiempo,
    String? urlImagen,
  }) {
    _nombreCtrl.text = nombre ?? '';
    _precioCtrl.text = precio?.toString() ?? '';
    _descripcionCtrl.text = descripcion ?? '';
    _tiempoCtrl.text = tiempo ?? '';
    _urlImagenCtrl.text = urlImagen ?? '';

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
              TextField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción breve',
                ),
              ),
              TextField(
                controller: _tiempoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tiempo (ej: 30-45 min)',
                ),
              ),
              TextField(
                controller: _urlImagenCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de la imagen (Referencial)',
                ),
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
    final String descripcion = _descripcionCtrl.text.trim();
    final String tiempo = _tiempoCtrl.text.trim();
    final String urlImagen = _urlImagenCtrl.text.trim();

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
      final Map<String, dynamic> datosPlato = {
        'nombre': nombre,
        'precio': precio,
        'descripcion': descripcion,
        'tiempo': tiempo,
        'urlImagen': urlImagen,
      };

      if (id == null) {
        await ref.add(datosPlato);
      } else {
        await ref.doc(id).update(datosPlato);
      }

      _nombreCtrl.clear();
      _precioCtrl.clear();
      _descripcionCtrl.clear();
      _tiempoCtrl.clear();
      _urlImagenCtrl.clear();

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

  void _confirmacionBorrar(String id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar platillo?'),
        content: Text('¿Estás seguro de que deseas eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _eliminarPlato(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No hay platos registrados.'));
          }

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
                          descripcion: data['descripcion'],
                          tiempo: data['tiempo'],
                          urlImagen: data['urlImagen'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _confirmacionBorrar(doc.id, data['nombre']),
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
