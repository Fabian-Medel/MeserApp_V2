import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../estado/app_state.dart';
import 'vista_pedido_cliente.dart';
import 'carrito.dart';

class EsperaPago extends StatefulWidget {
  final String notificacionId;

  const EsperaPago({super.key, required this.notificacionId});

  @override
  State<EsperaPago> createState() => _EsperaPagoState();
}

class _EsperaPagoState extends State<EsperaPago> {
  bool _navegando = false;
  bool _cancelando = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor, espera a que el mesero confirme tu pago o cancela la operación.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.indigo,
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(appState.restauranteId)
              .collection('notificaciones')
              .doc(widget.notificacionId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Error de conexión',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final estado = data['estado'];

              if ((estado == 'completado' || estado == 'archivado') &&
                  !_navegando &&
                  !_cancelando) {
                _navegando = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VistaPedidoCliente(),
                    ),
                    (route) => route.isFirst,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Pago recibido! Tu pedido va a cocina.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              }
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payments, size: 100, color: Colors.white),
                    const SizedBox(height: 30),
                    const Text(
                      'Un mesero está en camino a tu mesa para procesar el pago en efectivo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_cancelando)
                      const CircularProgressIndicator(color: Colors.red)
                    else
                      const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'Por favor espera...',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 50),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text(
                        'Cancelar Pago',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                      ),
                      onPressed: _cancelando
                          ? null
                          : () async {
                              setState(() => _cancelando = true);

                              await appState.cancelarPagoEfectivo(
                                widget.notificacionId,
                              );

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Pago cancelado. Puedes modificar tu carrito.',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const Carrito(),
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
