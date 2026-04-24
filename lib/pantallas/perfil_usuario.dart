import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'inicio.dart';

class PerfilUsuario extends StatefulWidget {
  const PerfilUsuario({super.key});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  User? usuario = FirebaseAuth.instance.currentUser;
  final _nombreEditCtrl = TextEditingController();

  void _mostrarDialogoEdicion() {
    _nombreEditCtrl.text = usuario?.displayName ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Nombre del Restaurante'),
          content: TextField(
            controller: _nombreEditCtrl,
            decoration: const InputDecoration(
              labelText: 'Nuevo nombre',
              hintText: 'Ej: Las Viejas Cochinas',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => _guardarNombre(),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _guardarNombre() async {
    String nuevoNombre = _nombreEditCtrl.text.trim();

    if (nuevoNombre.isEmpty) return;

    try {
      await usuario?.updateDisplayName(nuevoNombre);

      await usuario?.reload();

      setState(() {
        usuario = FirebaseAuth.instance.currentUser;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nombre actualizado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el nombre'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil del Restaurante',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.indigo.shade100,
                backgroundImage: usuario?.photoURL != null
                    ? NetworkImage(usuario!.photoURL!)
                    : null,
                child: usuario?.photoURL == null
                    ? const Icon(Icons.store, size: 60, color: Colors.indigo)
                    : null,
              ),
              const SizedBox(height: 20),
              Text(
                usuario?.displayName ?? 'Restaurante sin nombre',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                usuario?.email ?? '',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const Spacer(),

              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Editar Nombre'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: _mostrarDialogoEdicion,
              ),
              const SizedBox(height: 15),

              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sesión cerrada correctamente'),
                        backgroundColor: Colors.blueGrey,
                      ),
                    );
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const Inicio()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
