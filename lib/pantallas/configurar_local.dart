import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'contenedor_staff.dart';

class ConfigurarLocal extends StatefulWidget {
  final String restauranteId;

  const ConfigurarLocal({super.key, required this.restauranteId});

  @override
  State<ConfigurarLocal> createState() => _ConfigurarLocalState();
}

class _ConfigurarLocalState extends State<ConfigurarLocal> {
  final _nombreJefeCtrl = TextEditingController();
  final _nombreRestCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _guardando = false;

  void _guardarConfiguracion() async {
    final nombreJefe = _nombreJefeCtrl.text.trim();
    final nombreRest = _nombreRestCtrl.text.trim();
    final direccion = _direccionCtrl.text.trim();
    final telefono = _telefonoCtrl.text.trim();

    if (nombreJefe.isEmpty ||
        nombreRest.isEmpty ||
        direccion.isEmpty ||
        telefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los campos son obligatorios.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.restauranteId)
          .update({'nombre': nombreJefe});

      await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(widget.restauranteId)
          .set({
            'nombre': nombreRest,
            'direccion': direccion,
            'telefono': telefono,
            'configurado': true,
          }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(widget.restauranteId)
          .collection('mesas')
          .doc('1')
          .set({
            'numero': 1,
            'estado': 0, // 0 = Libre
            'id': '1|${widget.restauranteId}',
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Local configurado con éxito! Mesa 1 habilitada.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ContenedorStaff()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración Inicial'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu, size: 60, color: Colors.indigo),
              const SizedBox(height: 15),
              const Text(
                '¡Te damos la bienvenida! Configura los datos de tu restaurante para comenzar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nombreJefeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tu Nombre (Administrador/Jefe)*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nombreRestCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Restaurante*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dirección del Local*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de Contacto*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 35),
              _guardando
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _guardarConfiguracion,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Finalizar Configuración',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
