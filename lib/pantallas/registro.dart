import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<Registro> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _ocultarPassword = true;
  bool _cargando = false;

  void mostrarAlertaPersonalizada(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  bool validarCampos() {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      mostrarAlertaPersonalizada(
        'Por favor, ingresa un correo electrónico válido.',
      );
      return false;
    }
    if (pass.length < 8) {
      mostrarAlertaPersonalizada(
        'La contraseña debe tener al menos 8 caracteres.',
      );
      return false;
    }
    if (!pass.contains(RegExp(r'[A-Z]'))) {
      mostrarAlertaPersonalizada(
        'La contraseña debe tener al menos una letra mayúscula.',
      );
      return false;
    }
    if (!pass.contains(RegExp(r'[a-z]'))) {
      mostrarAlertaPersonalizada(
        'La contraseña debe tener al menos una letra minúscula.',
      );
      return false;
    }
    if (!pass.contains(RegExp(r'[0-9]'))) {
      mostrarAlertaPersonalizada(
        'La contraseña debe tener al menos un número.',
      );
      return false;
    }
    if (!pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>\-_]'))) {
      mostrarAlertaPersonalizada(
        'La contraseña debe tener al menos un símbolo especial (ej: ! @ #).',
      );
      return false;
    }
    if (pass != confirmPass) {
      mostrarAlertaPersonalizada('Las contraseñas no coinciden.');
      return false;
    }

    return true;
  }

  void registrarUsuario() async {
    if (!validarCampos()) return;

    setState(() => _cargando = true);

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );

      final usuario = credencial.user;

      if (usuario != null) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuario.uid)
            .set({
              'uid': usuario.uid,
              'email': _emailCtrl.text.trim(),
              'rol': 'jefe',
              'estado': 'activo',
              'restauranteId': usuario.uid,
              'nombre': 'Sin configurar',
              'disponible': false,
              'tareaActualId': null,
            });

        await FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(usuario.uid)
            .set({'configurado': false});

        if (!usuario.emailVerified) {
          await usuario.sendEmailVerification();
          await FirebaseAuth.instance.signOut();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '¡Registro exitoso! Te enviamos un enlace para verificar tu correo.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar usuario';
      if (e.code == 'email-already-in-use') {
        mensaje = 'Este correo ya está registrado.';
      }
      mostrarAlertaPersonalizada(mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta de Restaurante')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text(
                'Registra tus datos',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico*',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passCtrl,
                obscureText: _ocultarPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña*',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarPassword = !_ocultarPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPassCtrl,
                obscureText: _ocultarPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña*',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarPassword = !_ocultarPassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _cargando
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: registrarUsuario,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Registrarme',
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
