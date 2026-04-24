import 'package:flutter/material.dart';

import '../estado/app_state.dart';
import 'carrito.dart';

class Menu extends StatelessWidget {
  const Menu({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Menú - Mesa ${appState.mesaSeleccionada! + 1}'),
            automaticallyImplyLeading: false,
          ),
          body: ListView.builder(
            itemCount: appState.menu.length,
            itemBuilder: (context, index) {
              final item = appState.menu[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Icon(item['icono'], color: Colors.indigo),
                  ),
                  title: Text(
                    item['nombre'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('\$${item['precio']}'),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: Colors.green,
                      size: 30,
                    ),
                    onPressed: () {
                      appState.agregarAlCarrito(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item['nombre']} agregado'),
                          duration: const Duration(milliseconds: 500),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          bottomNavigationBar: appState.carrito.isEmpty
              ? null
              : BottomAppBar(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Carrito()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Ver Carrito (\$${appState.totalCarrito})',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
