import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'inicio.dart';
import 'contenedor_staff.dart';
import 'configurar_local.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  void _verificarSesion() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Inicio()),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final String rol = userData['rol'] ?? 'mesero';
        final String restId = userData['restauranteId'] ?? user.uid;

        if (rol == 'mesero' || rol == 'chef') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ContenedorStaff()),
          );
        } else if (rol == 'jefe') {
          if (user.emailVerified) {
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
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            );
          }
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Inicio()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Inicio()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 120, color: Colors.white),
            SizedBox(height: 25),
            Text(
              'MeserApp',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
