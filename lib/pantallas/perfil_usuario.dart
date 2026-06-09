import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inicio.dart';

class PerfilUsuario extends StatefulWidget {
  const PerfilUsuario({super.key});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  final User? usuario = FirebaseAuth.instance.currentUser;

  String _nombre = '';
  String _telefono = 'Sin configurar';
  String _direccion = 'Sin configurar';
  bool _cargando = true;

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatosRestaurante();
  }

  void _cargarDatosRestaurante() async {
    if (usuario == null) return;

    try {
      final documento = await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(usuario!.uid)
          .get();

      if (documento.exists) {
        final datos = documento.data() as Map<String, dynamic>;
        setState(() {
          _nombre = datos['nombre'] ?? usuario!.displayName ?? 'Sin nombre';
          _telefono = datos['telefono'] ?? 'Sin configurar';
          _direccion = datos['direccion'] ?? 'Sin configurar';
        });
      } else {
        setState(() {
          _nombre = usuario!.displayName ?? 'Sin nombre';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar datos'),
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
    _nombreCtrl.text = _nombre;
    _telefonoCtrl.text = _telefono == 'Sin configurar' ? '' : _telefono;
    _direccionCtrl.text = _direccion == 'Sin configurar' ? '' : _direccion;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Perfil'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Restaurante',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _guardarDatos,
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _guardarDatos() async {
    if (usuario == null) return;

    final nuevoNombre = _nombreCtrl.text.trim();
    final nuevoTelefono = _telefonoCtrl.text.trim();
    final nuevaDireccion = _direccionCtrl.text.trim();

    if (nuevoNombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre es obligatorio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context);

    setState(() {
      _cargando = true;
    });

    try {
      await usuario!.updateDisplayName(nuevoNombre);

      await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(usuario!.uid)
          .set({
            'nombre': nuevoNombre,
            'telefono': nuevoTelefono,
            'direccion': nuevaDireccion,
          }, SetOptions(merge: true));

      _cargarDatosRestaurante();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _cargando = false;
      });
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
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
                          ? const Icon(
                              Icons.store,
                              size: 60,
                              color: Colors.indigo,
                            )
                          : null,
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
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _direccion,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar Información'),
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
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Sesión cerrada correctamente',
                                          ),
                                          backgroundColor: Colors.blueGrey,
                                        ),
                                      );
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
                            );
                          },
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
