import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../estado/app_state.dart';

class Staff extends StatelessWidget {
  const Staff({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('restaurantes')
                      .doc(uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var data = snapshot.data!.data() as Map<String, dynamic>?;

                    if (data == null || !data.containsKey('mesas')) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<dynamic> mesasReales = data['mesas'];

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: mesasReales.length,
                      itemBuilder: (context, index) {
                        int estado = mesasReales[index];
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
                    );
                  },
                ),
              ),
              const Divider(height: 30, thickness: 2),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Text(
                  'Notificaciones',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: appState.notificaciones.isEmpty
                    ? const Center(
                        child: Text('No hay notificaciones pendientes'),
                      )
                    : ListView.builder(
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
