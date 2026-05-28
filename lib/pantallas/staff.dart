import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../estado/app_state.dart';
import 'lector_limpieza.dart';

class Staff extends StatefulWidget {
  const Staff({super.key});

  @override
  State<Staff> createState() => _StaffState();
}

class _StaffState extends State<Staff> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _procesando = false;

  Future<void> _tomarTarea(
    String tareaId,
    String coleccion,
    String tipo,
    String restauranteId,
  ) async {
    setState(() => _procesando = true);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference tareaRef = FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(restauranteId)
            .collection(coleccion)
            .doc(tareaId);

        DocumentSnapshot snapshot = await transaction.get(tareaRef);

        if (snapshot.exists &&
            (snapshot.data() as Map<String, dynamic>)['meseroAsignadoId'] !=
                null) {
          throw Exception('Ya tomada');
        }

        DocumentReference userRef = FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid);

        transaction.update(tareaRef, {
          'meseroAsignadoId': uid,
          'estado': 'en_proceso',
        });
        transaction.update(userRef, {
          'tareaActualId': tareaId,
          'coleccionOrigen': coleccion,
          'tipoTarea': tipo,
        });
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea ya asignada a otro.'),
            backgroundColor: Colors.orange,
          ),
        );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _finalizarTarea(
    String tareaId,
    String coleccion,
    String tipo,
    String restauranteId,
    int? mesaIndex,
  ) async {
    setState(() => _procesando = true);

    WriteBatch batch = FirebaseFirestore.instance.batch();
    DocumentReference tareaRef = FirebaseFirestore.instance
        .collection('restaurantes')
        .doc(restauranteId)
        .collection(coleccion)
        .doc(tareaId);
    DocumentReference userRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid);

    batch.update(tareaRef, {
      'estado': coleccion == 'pedidos' ? 'entregado' : 'completado',
    });
    batch.update(userRef, {
      'tareaActualId': null,
      'coleccionOrigen': FieldValue.delete(),
      'tipoTarea': FieldValue.delete(),
    });
    await batch.commit();

    if (tipo == 'limpieza' && mesaIndex != null) {
      appState.habilitarMesa(mesaIndex);
    }

    if (mounted) setState(() => _procesando = false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Panel de Operaciones',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.indigo,
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(uid)
                .snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData)
                return const Center(child: CircularProgressIndicator());

              final userData = userSnap.data!.data() as Map<String, dynamic>;
              final String? tareaActualId = userData['tareaActualId'];
              final String? coleccionOrigen = userData['coleccionOrigen'];
              final String? tipoTarea = userData['tipoTarea'];
              final String restId = userData['restauranteId'] ?? uid;

              return CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Text(
                        'Estado de las Mesas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 90,
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('restaurantes')
                            .doc(restId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists)
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          List<dynamic> mesas = snapshot.data!['mesas'];
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: mesas.length,
                            itemBuilder: (context, index) {
                              int estado = mesas[index];
                              return Container(
                                width: 80,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
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
                  ),
                  const SliverToBoxAdapter(
                    child: Divider(height: 30, thickness: 2),
                  ),

                  if (tareaActualId != null && coleccionOrigen != null)
                    SliverToBoxAdapter(
                      child: _construirTareaActual(
                        tareaActualId,
                        coleccionOrigen,
                        tipoTarea,
                        restId,
                      ),
                    )
                  else
                    _construirListasDisponibles(restId),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LectorLimpieza()),
            ),
            label: const Text(
              'Escanear QR',
              style: TextStyle(color: Colors.white),
            ),
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            backgroundColor: Colors.indigo,
          ),
        );
      },
    );
  }

  Widget _construirTareaActual(
    String tareaId,
    String coleccion,
    String? tipo,
    String restId,
  ) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(restId)
          .collection(coleccion)
          .doc(tareaId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null)
          return const Center(child: Text('La tarea fue cancelada.'));

        String titulo = coleccion == 'pedidos'
            ? 'ENTREGAR COMIDA\n(Mesa ${data['mesa']})'
            : '${tipo!.toUpperCase()}\n(Mesa ${data['mesa']})';

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 8,
            color: Colors.indigo.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_ind,
                    size: 60,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'TU TAREA ACTUAL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  _procesando
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle, size: 28),
                          label: const Text(
                            'Completar Tarea',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                          ),
                          onPressed: () => _finalizarTarea(
                            tareaId,
                            coleccion,
                            tipo ?? 'pedido',
                            restId,
                            data['mesa'] - 1,
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _construirListasDisponibles(String restId) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0),
            child: Text(
              'Tareas Pendientes:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('restaurantes')
                .doc(restId)
                .collection('pedidos')
                .where('estado', isEqualTo: 'listo')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final tareas = snapshot.data!.docs
                  .where((d) => (d.data() as Map)['meseroAsignadoId'] == null)
                  .toList();

              return Column(
                children: tareas.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.room_service,
                        color: Colors.orange,
                        size: 30,
                      ),
                      title: Text(
                        'Entregar a Mesa ${data['mesa']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: _procesando
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () => _tomarTarea(
                                doc.id,
                                'pedidos',
                                'pedido',
                                restId,
                              ),
                              child: const Text('Tomar'),
                            ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('restaurantes')
                .doc(restId)
                .collection('notificaciones')
                .where('estado', isEqualTo: 'pendiente')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final tareas = snapshot.data!.docs
                  .where((d) => (d.data() as Map)['meseroAsignadoId'] == null)
                  .toList();

              return Column(
                children: tareas.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  String tipo = data['tipo'];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: Icon(
                        tipo == 'limpieza'
                            ? Icons.cleaning_services
                            : Icons.pan_tool,
                        color: tipo == 'limpieza' ? Colors.red : Colors.blue,
                        size: 30,
                      ),
                      title: Text(
                        '${tipo.toUpperCase()} - Mesa ${data['mesa']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: _procesando
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () => _tomarTarea(
                                doc.id,
                                'notificaciones',
                                tipo,
                                restId,
                              ),
                              child: const Text('Tomar'),
                            ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
