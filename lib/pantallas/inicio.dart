import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'staff.dart';
import 'mesas.dart';
import 'login.dart';

class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 100, color: Colors.indigo),
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
                  MaterialPageRoute(builder: (_) => const Mesas()),
                );
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Ingresar como Restaurante'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(250, 50)),
              onPressed: () {
                final usuario = FirebaseAuth.instance.currentUser;

                if (usuario != null && usuario.emailVerified) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Staff()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
