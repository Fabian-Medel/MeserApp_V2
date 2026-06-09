import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registro.dart';
import 'contenedor_staff.dart';
import 'configurar_local.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _ocultarPassword = true;
  bool _cargando = false;

  void _enviarCorreoRecuperacion(String email) async {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un correo válido.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Correo de recuperación enviado. Revisa tu bandeja o la carpeta de Spam.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hubo un error. Verifica que el correo esté bien escrito.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarDialogoRecuperarContrasena() {
    final emailRecuperacionCtrl = TextEditingController(
      text: _emailCtrl.text.trim(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperar Contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailRecuperacionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final correo = emailRecuperacionCtrl.text.trim();
                Navigator.pop(context);
                _enviarCorreoRecuperacion(correo);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enviar enlace'),
            ),
          ],
        );
      },
    );
  }

  void intentarLogin() async {
    setState(() {
      _cargando = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text.trim(),
          );

      final user = userCredential.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final String rol = userData['rol'] ?? 'cliente';
          final String restId = userData['restauranteId'] ?? user.uid;

          if ((rol == 'jefe' || rol == 'cliente') && !user.emailVerified) {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Debes verificar tu correo antes de entrar. Revisa tu bandeja de entrada.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            setState(() {
              _cargando = false;
            });
            return;
          }

          if (!mounted) return;

          if (rol == 'mesero' || rol == 'chef') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ContenedorStaff()),
            );
          } else if (rol == 'jefe') {
            final restDoc = await FirebaseFirestore.instance
                .collection('restaurantes')
                .doc(restId)
                .get();
            if (!mounted) return;

            if (restDoc.exists && restDoc.data()?['configurado'] == true) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ContenedorStaff()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfigurarLocal(restauranteId: restId),
                ),
              );
            }
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario no registrado en la base de datos.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al iniciar sesión';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        mensaje = 'Correo o contraseña incorrectos.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
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

  void iniciarConGoogle() async {
    setState(() => _cargando = true);
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '776509224127-peb5aa78l6bok521q3l8f29csiiv94b5.apps.googleusercontent.com',
      );

      final GoogleSignInAccount usuarioGoogle = await GoogleSignIn.instance
          .authenticate();

      if (usuarioGoogle != null) {
        final GoogleSignInAuthentication authGoogle =
            usuarioGoogle.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: authGoogle.idToken,
        );

        final credencialFirebase = await FirebaseAuth.instance
            .signInWithCredential(credential);
        final usuario = credencialFirebase.user;

        if (usuario != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(usuario.uid)
              .get();

          if (!userDoc.exists) {
            await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(usuario.uid)
                .set({
                  'uid': usuario.uid,
                  'email': usuario.email ?? '',
                  'rol': 'jefe',
                  'estado': 'activo',
                  'restauranteId': usuario.uid,
                  'nombre': usuario.displayName ?? 'Sin configurar',
                  'disponible': false,
                  'tareaActualId': null,
                });

            await FirebaseFirestore.instance
                .collection('restaurantes')
                .doc(usuario.uid)
                .set({'configurado': false});

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ConfigurarLocal(restauranteId: usuario.uid),
              ),
            );
          } else {
            final userData = userDoc.data() as Map<String, dynamic>;
            final restId = userData['restauranteId'];
            final restDoc = await FirebaseFirestore.instance
                .collection('restaurantes')
                .doc(restId)
                .get();

            if (!mounted) return;
            if (restDoc.exists && restDoc.data()?['configurado'] == true) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ContenedorStaff()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfigurarLocal(restauranteId: restId),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al iniciar con Google o proceso cancelado'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso Empleados')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu, size: 80, color: Colors.indigo),
              const SizedBox(height: 20),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passCtrl,
                obscureText: _ocultarPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _mostrarDialogoRecuperarContrasena,
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _cargando
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: intentarLogin,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
              const Divider(height: 40),
              OutlinedButton.icon(
                label: const Text('Continuar con Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.black,
                ),
                onPressed: iniciarConGoogle,
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Registro()),
                  );
                },
                child: const Text('¿No tienes cuenta? Regístrate aquí'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
