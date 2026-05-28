import 'package:flutter/material.dart';
import '../estado/app_state.dart';
import 'vista_pedido_cliente.dart';

class Carrito extends StatelessWidget {
  const Carrito({super.key});

  void confirmarPedido(BuildContext context) async {
    await appState.enviarPedidoCocina();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VistaPedidoCliente()),
        (route) => route.isFirst,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido enviado a cocina.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Tu Pedido')),
      body: Column(
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
                  subtitle: Text('Precio unitario: \$${producto['precio']}'),
                  trailing: Text(
                    'Cant: ${producto['cantidad']}',
                    style: const TextStyle(fontSize: 16),
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
                ElevatedButton(
                  onPressed: () => confirmarPedido(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Confirmar Pedido a Cocina',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
