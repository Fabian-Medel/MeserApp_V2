import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../estado/app_state.dart';
import 'menu.dart';

class LectorQR extends StatefulWidget {
  final int indexMesa;
  final String idRestauranteDetectado;

  const LectorQR({
    super.key,
    required this.indexMesa,
    required this.idRestauranteDetectado,
  });

  @override
  State<LectorQR> createState() => _LectorQRState();
}

class _LectorQRState extends State<LectorQR> {
  bool yaDetectado = false;

  void procesarEscaneoExitoso() {
    if (!yaDetectado) {
      yaDetectado = true;

      appState.setRestauranteId(widget.idRestauranteDetectado);

      appState.ocuparMesa(widget.indexMesa);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Menu()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: (capture) => procesarEscaneoExitoso()),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Simular lectura de QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(250, 55),
                ),
                onPressed: procesarEscaneoExitoso,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
