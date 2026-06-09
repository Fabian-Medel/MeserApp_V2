import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seleccion_restaurante.dart';
import 'login.dart';
import 'contenedor_staff.dart';
import 'configurar_local.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  bool _verificando = false;

  void _ingresarComoRestaurante() async {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
      return;
    }

    setState(() => _verificando = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String rol = userData['rol'] ?? 'mesero';
        final String restId = userData['restauranteId'] ?? usuario.uid;

        if (rol == 'mesero' || rol == 'chef') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContenedorStaff()),
          );
        } else if (rol == 'jefe') {
          if (usuario.emailVerified) {
            final restDoc = await FirebaseFirestore.instance
                .collection('restaurantes')
                .doc(restId)
                .get();
            if (!mounted) return;

            if (restDoc.exists && restDoc.data()?['configurado'] == true) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContenedorStaff()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfigurarLocal(restauranteId: restId),
                ),
              );
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            );
          }
        }
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _verificando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _verificando
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Verificando credenciales...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 100,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MeserApp',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Ingresar como Cliente'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SeleccionRestaurante(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Ingresar como Restaurante'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                    ),
                    onPressed: _ingresarComoRestaurante,
                  ),
                ],
              ),
      ),
    );
  }
}
