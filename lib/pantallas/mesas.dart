import 'package:flutter/material.dart';

import '../estado/app_state.dart';
import 'qr.dart';

class Mesas extends StatelessWidget {
  const Mesas({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Seleccionar Mesa')),
          body: GridView.builder(
            padding: const EdgeInsets.all(15),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: appState.mesas.length,
            itemBuilder: (context, index) {
              int estado = appState.mesas[index];
              Color colorMesa = estado == 0
                  ? Colors.green.shade400
                  : (estado == 1
                        ? Colors.red.shade400
                        : Colors.orange.shade400);
              String textoMesa = estado == 0
                  ? 'Libre'
                  : (estado == 1 ? 'Ocupada' : 'Limpiando');
              IconData iconoMesa = estado == 0
                  ? Icons.check_circle
                  : (estado == 1 ? Icons.cancel : Icons.cleaning_services);
              return GestureDetector(
                onTap: estado == 0
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LectorQR(indexMesa: index),
                          ),
                        );
                      }
                    : null,
                child: Card(
                  color: colorMesa,
                  elevation: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mesa ${index + 1}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Icon(iconoMesa, color: Colors.white, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        textoMesa,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
