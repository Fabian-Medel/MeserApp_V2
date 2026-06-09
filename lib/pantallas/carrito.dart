import 'package:flutter/material.dart';
import '../estado/app_state.dart';
import 'vista_pedido_cliente.dart';
import 'espera_pago.dart';

class Carrito extends StatefulWidget {
  const Carrito({super.key});

  @override
  State<Carrito> createState() => _CarritoState();
}

class _CarritoState extends State<Carrito> {
  bool _procesando = false;

  void _pagarConTarjeta() async {
    setState(() => _procesando = true);
    bool exito = await appState.enviarPedidoTarjeta();

    if (mounted && exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago exitoso. Pedido enviado a cocina.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VistaPedidoCliente()),
        (route) => route.isFirst,
      );
    } else {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _pagarEnEfectivo() async {
    setState(() => _procesando = true);
    String? idNotificacion = await appState.enviarPedidoEfectivo();

    if (mounted && idNotificacion != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => EsperaPago(notificacionId: idNotificacion),
        ),
        (route) => route.isFirst,
      );
    } else {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu Pedido')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final carritoAgrupado = <String, Map<String, dynamic>>{};

          for (var item in appState.carrito) {
            if (carritoAgrupado.containsKey(item['nombre'])) {
              carritoAgrupado[item['nombre']]!['cantidad'] += 1;
            } else {
              carritoAgrupado[item['nombre']] = {
                'nombre': item['nombre'],
                'precio': item['precio'],
                'cantidad': 1,
              };
            }
          }
          final listaFinal = carritoAgrupado.values.toList();

          if (listaFinal.isEmpty) {
            return const Center(
              child: Text(
                'Tu carrito está vacío',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: listaFinal.length,
                  itemBuilder: (context, index) {
                    final producto = listaFinal[index];
                    return ListTile(
                      title: Text(
                        producto['nombre'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Precio unitario: \$${producto['precio']}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                appState.eliminarDelCarrito(producto['nombre']),
                          ),
                          Text(
                            '${producto['cantidad']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              final platoOriginal = appState.carrito.firstWhere(
                                (p) => p['nombre'] == producto['nombre'],
                              );
                              appState.agregarAlCarrito(platoOriginal);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Total a pagar: \$${appState.totalCarrito}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (_procesando)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.credit_card),
                        onPressed: _pagarConTarjeta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        label: const Text(
                          'Pagar con Tarjeta (Demo)',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.payments),
                        onPressed: _pagarEnEfectivo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        label: const Text(
                          'Pagar en Efectivo al Mesero',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
