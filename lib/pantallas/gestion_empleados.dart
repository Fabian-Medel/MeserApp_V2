import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class GestionEmpleados extends StatefulWidget {
  const GestionEmpleados({super.key});

  @override
  State<GestionEmpleados> createState() => _GestionEmpleadosState();
}

class _GestionEmpleadosState extends State<GestionEmpleados> {
  final User? jefe = FirebaseAuth.instance.currentUser;

  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String _rolSeleccionado = 'mesero';
  bool _procesando = false;

  bool _ocultarPassword = true;

  void _mostrarAlerta(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool _validarCampos(
    String nombre,
    String email,
    String pass,
    String confirmPass,
    bool esNuevo,
  ) {
    if (nombre.isEmpty || email.isEmpty || (esNuevo && pass.isEmpty)) {
      _mostrarAlerta(
        'Por favor, completa todos los campos obligatorios.',
        Colors.orange.shade800,
      );
      return false;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      _mostrarAlerta(
        'Por favor, ingresa un correo electrónico válido.',
        Colors.orange.shade800,
      );
      return false;
    }

    if (esNuevo) {
      if (pass.length < 8) {
        _mostrarAlerta(
          'La contraseña debe tener al menos 8 caracteres.',
          Colors.orange.shade800,
        );
        return false;
      }
      if (!pass.contains(RegExp(r'[A-Z]'))) {
        _mostrarAlerta(
          'La contraseña debe tener al menos una letra mayúscula.',
          Colors.orange.shade800,
        );
        return false;
      }
      if (!pass.contains(RegExp(r'[a-z]'))) {
        _mostrarAlerta(
          'La contraseña debe tener al menos una letra minúscula.',
          Colors.orange.shade800,
        );
        return false;
      }
      if (!pass.contains(RegExp(r'[0-9]'))) {
        _mostrarAlerta(
          'La contraseña debe tener al menos un número.',
          Colors.orange.shade800,
        );
        return false;
      }
      if (!pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>\-_]'))) {
        _mostrarAlerta(
          'Debe incluir un símbolo especial (ej: ! @ #).',
          Colors.orange.shade800,
        );
        return false;
      }
      if (pass != confirmPass) {
        _mostrarAlerta('Las contraseñas no coinciden.', Colors.orange.shade800);
        return false;
      }
    }

    return true;
  }

  void _abrirFormulario({
    String? id,
    String? nombre,
    String? email,
    String? rol,
  }) {
    _nombreCtrl.text = nombre ?? '';
    _emailCtrl.text = email ?? '';
    _passCtrl.clear();
    _confirmPassCtrl.clear();
    _rolSeleccionado = rol ?? 'mesero';
    _ocultarPassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(id == null ? 'Nuevo Empleado' : 'Editar Empleado'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo*',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico*',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: id == null,
                ),
                if (id == null) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _ocultarPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña*',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            _ocultarPassword = !_ocultarPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmPassCtrl,
                    obscureText: _ocultarPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña*',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            _ocultarPassword = !_ocultarPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: _rolSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'mesero', child: Text('Mesero')),
                    DropdownMenuItem(value: 'chef', child: Text('Chef')),
                  ],
                  onChanged: (val) {
                    setStateDialog(() => _rolSeleccionado = val!);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Rol del Trabajador',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _procesando ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _procesando
                  ? null
                  : () async {
                      final nom = _nombreCtrl.text.trim();
                      final mail = _emailCtrl.text.trim();
                      final psw = _passCtrl.text.trim();
                      final cpsw = _confirmPassCtrl.text.trim();

                      if (!_validarCampos(nom, mail, psw, cpsw, id == null)) {
                        return;
                      }

                      setStateDialog(() => _procesando = true);
                      await _guardarEmpleado(id, nom, mail, psw);
                      setStateDialog(() => _procesando = false);
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: _procesando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Guardar',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarEmpleado(
    String? id,
    String nombre,
    String email,
    String pass,
  ) async {
    try {
      if (id == null) {
        FirebaseApp appSecundaria = await Firebase.initializeApp(
          name: 'ConexionSecundaria',
          options: Firebase.app().options,
        );

        try {
          UserCredential credencial = await FirebaseAuth.instanceFor(
            app: appSecundaria,
          ).createUserWithEmailAndPassword(email: email, password: pass);

          final nuevoUsuarioId = credencial.user!.uid;

          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(nuevoUsuarioId)
              .set({
                'uid': nuevoUsuarioId,
                'nombre': nombre,
                'email': email,
                'rol': _rolSeleccionado,
                'estado': 'activa',
                'restauranteId': jefe!.uid,
                'disponible': true,
                'tareaActualId': null,
              });
        } finally {
          await appSecundaria.delete();
        }
      } else {
        await FirebaseFirestore.instance.collection('usuarios').doc(id).update({
          'nombre': nombre,
          'rol': _rolSeleccionado,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        _mostrarAlerta('Empleado guardado con éxito.', Colors.green);
      }
    } on FirebaseAuthException catch (e) {
      String msj = 'Error en las credenciales.';
      if (e.code == 'email-already-in-use') {
        msj = 'Ese correo ya está registrado por otra persona.';
      }
      _mostrarAlerta(msj, Colors.red);
    } catch (e) {
      _mostrarAlerta('Error en la base de datos: $e', Colors.red);
    }
  }

  void _eliminarEmpleado(String id, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Salida'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "$nombre" del sistema? Esta acción revocará todos sus accesos de inmediato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(id)
                    .delete();
                if (mounted) {
                  Navigator.pop(context);
                  _mostrarAlerta(
                    'Empleado desvinculado con éxito.',
                    Colors.blueGrey,
                  );
                }
              } catch (e) {
                _mostrarAlerta('No se pudo borrar el registro: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Despedir / Eliminar',
              style: TextStyle(color: Colors.white),
            ),
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
          'Gestión de Personal',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('restauranteId', isEqualTo: jefe?.uid)
            .where('rol', whereIn: ['mesero', 'chef'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay empleados registrados en este local.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final empleados = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: empleados.length,
            itemBuilder: (context, index) {
              final doc = empleados[index];
              final emp = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: emp['rol'] == 'chef'
                        ? Colors.orange.shade700
                        : Colors.blue.shade700,
                    child: Icon(
                      emp['rol'] == 'chef'
                          ? Icons.soup_kitchen
                          : Icons.room_service,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    emp['nombre'] ?? 'Empleado sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Correo: ${emp['email']}\nRol: ${emp['rol'].toString().toUpperCase()}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _abrirFormulario(
                          id: doc.id,
                          nombre: emp['nombre'],
                          email: emp['email'],
                          rol: emp['rol'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _eliminarEmpleado(doc.id, emp['nombre'] ?? ''),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Nuevo Empleado',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
