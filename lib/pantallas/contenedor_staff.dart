import 'package:flutter/material.dart';
import 'package:meserapp/pantallas/gestion_menu.dart';
import 'staff.dart';
import 'perfil_usuario.dart';

class ContenedorStaff extends StatefulWidget {
  const ContenedorStaff({super.key});

  @override
  State<ContenedorStaff> createState() => _ContenedorStaffState();
}

class _ContenedorStaffState extends State<ContenedorStaff> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = [
    const Staff(),
    const GestionMenu(),
    const PerfilUsuario(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_restaurant),
            label: 'Mesas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menú',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
