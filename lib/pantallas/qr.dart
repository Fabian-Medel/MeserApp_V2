import 'package:flutter/material.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../estado/app_state.dart';
import 'menu.dart';

class LectorQR extends StatefulWidget {
  final int indexMesa;
  const LectorQR({super.key, required this.indexMesa});

  @override
  State<LectorQR> createState() => _LectorQRState();
}

class _LectorQRState extends State<LectorQR> {
  bool yaDetectado = false;

  void procesarEscaneoExitoso() {
    if (!yaDetectado) {
      yaDetectado = true;
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
        title: const Text(
          'Escanear QR de la Mesa',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                procesarEscaneoExitoso();
              }
            },
          ),

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

          const Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Apunta a cualquier QR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  backgroundColor: Colors.black54,
                ),
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
                  textStyle: const TextStyle(fontSize: 18),
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
