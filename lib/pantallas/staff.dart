import 'package:flutter/material.dart';

import '../estado/app_state.dart';
import 'perfil_usuario.dart';

class Staff extends StatelessWidget {
  const Staff({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Administración',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.indigo,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PerfilUsuario()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(15.0),
                child: Text(
                  'Estado de las Mesas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: appState.mesas.length,
                  itemBuilder: (context, index) {
                    int estado = appState.mesas[index];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: estado == 0
                            ? Colors.green.shade400
                            : (estado == 1
                                  ? Colors.red.shade400
                                  : Colors.orange.shade400),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 30, thickness: 2),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Text(
                  'Notificaciones (Mesas por limpiar)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: appState.notificaciones.length,
                  itemBuilder: (context, index) {
                    final notif = appState.notificaciones[index];
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(
                          Icons.cleaning_services,
                          color: Colors.orange,
                          size: 30,
                        ),
                        title: Text(
                          'Mesa ${notif['mesa']} pagó su cuenta',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Artículos pedidos: ${notif['pedido'].length}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            appState.habilitarMesa(notif['mesa'] - 1);
                            appState.borrarNotificacion(index);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Limpiar'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
