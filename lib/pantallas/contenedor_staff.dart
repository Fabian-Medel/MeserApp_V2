import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../estado/app_state.dart';
import 'staff.dart';
import 'gestion_menu.dart';
import 'menu.dart';
import 'perfil_usuario.dart';
import 'perfil_empleado.dart';
import 'gestion_empleados.dart';
import 'vista_chef.dart';
import 'dashboard.dart';
import 'gestion_mesas.dart';

class ContenedorStaff extends StatefulWidget {
  const ContenedorStaff({super.key});

  @override
  State<ContenedorStaff> createState() => _ContenedorStaffState();
}

class _ContenedorStaffState extends State<ContenedorStaff> {
  int _indiceActual = 0;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Error al verificar permisos.')),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String rol = userData['rol'] ?? 'mesero';
        final String restId = userData['restauranteId'] ?? _uid;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (appState.restauranteId != restId) {
            appState.setRestauranteId(restId);
          }
        });

        List<Widget> pantallas = [];
        List<BottomNavigationBarItem> barraItems = [];

        if (rol == 'jefe') {
          pantallas = [
            const DashboardAdministrativo(),
            const GestionMenu(),
            const GestionEmpleados(),
            const GestionMesas(),
            const PerfilUsuario(),
          ];
          barraItems = const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Menú',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Personal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_bar),
              label: 'Mesas',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        } else if (rol == 'chef') {
          pantallas = [const VistaChef(), const Menu(), const PerfilEmpleado()];
          barraItems = const [
            BottomNavigationBarItem(
              icon: Icon(Icons.soup_kitchen),
              label: 'Cocina',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Menú',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        } else {
          pantallas = [const Staff(), const Menu(), const PerfilEmpleado()];
          barraItems = const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Panel de Tareas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Menú',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ];
        }

        if (_indiceActual >= pantallas.length) _indiceActual = 0;

        return Scaffold(
          body: pantallas[_indiceActual],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _indiceActual,
            selectedItemColor: Colors.indigo,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) => setState(() => _indiceActual = index),
            items: barraItems,
          ),
        );
      },
    );
  }
}