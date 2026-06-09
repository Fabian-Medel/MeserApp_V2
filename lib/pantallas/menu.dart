import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../estado/app_state.dart';
import 'carrito.dart';
import 'detalle_plato.dart';
import 'inicio.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});
  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  bool isChef = false;

  @override
  void initState() {
    super.initState();
    _verificarRol();
  }

  void _verificarRol() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (mounted && doc.exists && doc.data()!['rol'] == 'chef') {
        setState(() => isChef = true);
      }
    }
  }

  void _marcarAgotado(String idPlato, bool estadoActual) {
    FirebaseFirestore.instance
        .collection('restaurantes')
        .doc(appState.restauranteId)
        .collection('platos')
        .doc(idPlato)
        .update({'agotado': !estadoActual});
  }

  void _mostrarConfirmacionAsistencia(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Solicitar Asistencia?'),
        content: const Text(
          'Llamaremos a un mesero a tu mesa. Usa esta opción solo si requieres ayuda presencial o tienes alguna duda con el menú.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              appState.solicitarAsistencia();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Un mesero va en camino...'),
                  backgroundColor: Colors.indigo,
                ),
              );
            },
            child: const Text(
              'Llamar Mesero',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (appState.mesaSeleccionada != null) {
          if (appState.carrito.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vacía tu carrito primero para salir.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          final pedidos = await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(appState.restauranteId)
              .collection('pedidos')
              .where('mesa', isEqualTo: appState.mesaSeleccionada!)
              .where('estado', isNotEqualTo: 'archivado')
              .get();

          if (pedidos.docs.isNotEmpty && mounted) {
            Navigator.of(context).pop();
          } else if (mounted) {
            bool? salir = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('¿Abandonar mesa?'),
                content: const Text(
                  'Aún no has ordenado nada. La mesa quedará libre inmediatamente.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Quedarme'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Abandonar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
            if (salir == true && mounted) {
              appState.abandonarMesaVirtual();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Inicio()),
                (route) => false,
              );
            }
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            appState.mesaSeleccionada != null
                ? 'Menú - Mesa ${appState.mesaSeleccionada!}'
                : 'Consulta de Menú',
          ),
          leading: appState.mesaSeleccionada != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.maybePop(context),
                )
              : null,
          automaticallyImplyLeading: appState.mesaSeleccionada == null,
          actions: [
            if (appState.mesaSeleccionada != null &&
                appState.restauranteId != null)
              // ANTI-SPAM DE ASISTENCIA
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('restaurantes')
                    .doc(appState.restauranteId)
                    .collection('notificaciones')
                    .where('mesa', isEqualTo: appState.mesaSeleccionada)
                    .where('estado', whereIn: ['pendiente', 'en_proceso'])
                    .snapshots(),
                builder: (context, snapshot) {
                  bool ocupado =
                      snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                  return IconButton(
                    icon: Icon(
                      Icons.room_service,
                      color: ocupado ? Colors.white30 : Colors.white,
                    ),
                    tooltip: ocupado
                        ? 'Mesero en camino'
                        : 'Solicitar Asistencia',
                    onPressed: ocupado
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Un mesero ya está en camino a tu mesa.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        : () => _mostrarConfirmacionAsistencia(context),
                  );
                },
              ),
          ],
        ),
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            if (appState.restauranteId == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.indigo),
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('restaurantes')
                  .doc(appState.restauranteId)
                  .collection('platos')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text('Error al cargar.'));
                }
                final platos = snapshot.data!.docs;
                if (platos.isEmpty) {
                  return const Center(child: Text('Menú vacío.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: platos.length,
                  itemBuilder: (context, index) {
                    final docPlato = platos[index];
                    final item = docPlato.data() as Map<String, dynamic>;
                    final bool agotado = item['agotado'] ?? false;
                    final int cant = appState.cantidadEnCarrito(item['nombre']);

                    return GestureDetector(
                      onTap: agotado
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetallePlato(plato: item),
                              ),
                            ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Image.network(
                                item['urlImagen'] ??
                                    'https://via.placeholder.com/400x200',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                              ),
                              if (isChef)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: IconButton(
                                      icon: Icon(
                                        agotado
                                            ? Icons.toggle_off
                                            : Icons.toggle_on,
                                        color: agotado
                                            ? Colors.red
                                            : Colors.green,
                                        size: 30,
                                      ),
                                      onPressed: () =>
                                          _marcarAgotado(docPlato.id, agotado),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 15,
                                left: 15,
                                right: 15,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nombre'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item['tiempo'] ?? '20'} min - \$${item['precio']}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (agotado)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(
                                                0.9,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'AGOTADO',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        else if (appState.mesaSeleccionada !=
                                            null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (cant > 0) ...[
                                                  GestureDetector(
                                                    onTap: () => appState
                                                        .eliminarDelCarrito(
                                                          item['nombre'],
                                                        ),
                                                    child: const Icon(
                                                      Icons.remove_circle,
                                                      color: Colors.redAccent,
                                                      size: 28,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    '$cant',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Colors.indigo,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                ],
                                                GestureDetector(
                                                  onTap: () => appState
                                                      .agregarAlCarrito(item),
                                                  child: const Icon(
                                                    Icons.add_circle,
                                                    color: Colors.green,
                                                    size: 28,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            if (appState.carrito.isEmpty || appState.mesaSeleccionada == null) {
              return const SizedBox.shrink();
            }
            return BottomAppBar(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Carrito()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: Text('Ver Carrito (\$${appState.totalCarrito})'),
              ),
            );
          },
        ),
      ),
    );
  }
}
