import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inicio.dart';

class PerfilEmpleado extends StatefulWidget {
  const PerfilEmpleado({super.key});

  @override
  State<PerfilEmpleado> createState() => _PerfilEmpleadoState();
}

class _PerfilEmpleadoState extends State<PerfilEmpleado> {
  final User? usuario = FirebaseAuth.instance.currentUser;

  String _nombre = '';
  String _rol = '';
  String _telefono = 'Sin configurar';
  bool _cargando = true;

  final _telefonoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosEmpleado();
  }

  void _cargarDatosEmpleado() async {
    if (usuario == null) return;

    try {
      final documento = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario!.uid)
          .get();

      if (documento.exists) {
        final datos = documento.data() as Map<String, dynamic>;
        setState(() {
          _nombre = datos['nombre'] ?? 'Sin nombre';
          _rol = datos['rol'] ?? 'mesero';
          _telefono = datos['telefono'] ?? 'Sin configurar';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar datos del perfil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  void _mostrarDialogoEdicion() {
    _telefonoCtrl.text = _telefono == 'Sin configurar' ? '' : _telefono;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Teléfono de Contacto'),
          content: TextField(
            controller: _telefonoCtrl,
            decoration: const InputDecoration(labelText: 'Número de Teléfono'),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _guardarTelefono,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _guardarTelefono() async {
    if (usuario == null) return;
    final nuevoTelefono = _telefonoCtrl.text.trim();

    Navigator.pop(context);
    setState(() => _cargando = true);

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario!.uid)
          .update({
            'telefono': nuevoTelefono.isEmpty
                ? 'Sin configurar'
                : nuevoTelefono,
          });

      _cargarDatosEmpleado();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teléfono actualizado con éxito'),
            backgroundColor: Colors.green,
          ),
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
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil de Trabajo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.indigo.shade100,
                      child: const Icon(
                        Icons.badge,
                        size: 60,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _nombre,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Rol: ${_rol.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.indigo.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      usuario?.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone, size: 18, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          _telefono,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar Teléfono'),
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
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Confirmar salida'),
                            content: const Text(
                              '¿Estás seguro de que deseas cerrar sesión?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  await FirebaseAuth.instance.signOut();
                                  if (mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const Inicio(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                },
                                child: const Text(
                                  'Cerrar Sesión',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
