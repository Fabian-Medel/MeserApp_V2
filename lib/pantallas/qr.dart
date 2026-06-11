import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../estado/app_state.dart';
import 'menu.dart';

class LectorQR extends StatefulWidget {
  const LectorQR({super.key});

  @override
  State<LectorQR> createState() => _LectorQRState();
}

class _LectorQRState extends State<LectorQR> {
  bool yaDetectado = false;

  void procesarEscaneoExitoso(String? codigoLeido) {
    if (yaDetectado) return;
    if (codigoLeido == null) return;

    final partes = codigoLeido.trim().split('|');

    if (partes.length == 2) {
      int? numeroMesa = int.tryParse(partes[0]);
      String idRestaurante = partes[1];

      if (numeroMesa != null && idRestaurante.isNotEmpty) {
        setState(() => yaDetectado = true);

        appState.setRestauranteId(idRestaurante);
        appState.ocuparMesa(numeroMesa);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Menu()),
        );
        return;
      }
    }

    setState(() => yaDetectado = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código QR inválido o no reconocido.'),
        backgroundColor: Colors.red,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => yaDetectado = false);
    });
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
          MobileScanner(
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  procesarEscaneoExitoso(barcode.rawValue);
                }
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
        ],
      ),
    );
  }
}
