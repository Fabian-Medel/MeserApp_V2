import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../estado/app_state.dart';

class LectorLimpieza extends StatefulWidget {
  const LectorLimpieza({super.key});

  @override
  State<LectorLimpieza> createState() => _LectorLimpiezaState();
}

class _LectorLimpiezaState extends State<LectorLimpieza> {
  bool yaDetectado = false;
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _procesarEscaneo(String codigoLeido) {
    if (yaDetectado) return;

    int? numeroMesa;
    String? restauranteIdLeido;

    if (codigoLeido.contains('|')) {
      final partes = codigoLeido.split('|');
      numeroMesa = int.tryParse(partes[0]);
      restauranteIdLeido = partes.length > 1 ? partes[1] : null;
    } else {
      numeroMesa = int.tryParse(codigoLeido.trim());
    }

    if (numeroMesa != null && numeroMesa > 0) {
      setState(() => yaDetectado = true);

      if (restauranteIdLeido != null) {
        appState.setRestauranteId(restauranteIdLeido);
      }

      _mostrarControlMesa(numeroMesa);
    } else {
      setState(() => yaDetectado = true);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Inválido: Formato de mesa no reconocido.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => yaDetectado = false);
      });
    }
  }

  void _mostrarControlMesa(int numeroMesa) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(uid)
              .collection('mesas')
              .doc('$numeroMesa')
              .snapshots(),
          builder: (context, snapshot) {
            String estadoTexto = "Cargando...";
            Color estadoColor = Colors.grey;
            int estadoActual = -1;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              estadoActual = data['estado'] ?? 0;
              if (estadoActual == 0) {
                estadoTexto = "LIBRE";
                estadoColor = Colors.green;
              } else if (estadoActual == 1) {
                estadoTexto = "OCUPADA";
                estadoColor = Colors.red;
              } else {
                estadoTexto = "POR LIMPIAR";
                estadoColor = Colors.orange;
              }
            }

            return AlertDialog(
              title: Text('Control Mesa $numeroMesa'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Estado actual:'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      estadoTexto,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => yaDetectado = false);
                  },
                  child: const Text('Cerrar'),
                ),
                if (estadoActual != 0)
                  ElevatedButton(
                    onPressed: () async {
                      bool exito = await appState.habilitarMesa(numeroMesa);
                      if (!context.mounted) return;

                      if (exito) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo liberar la mesa.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() => yaDetectado = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text(
                      'Habilitar Mesa',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lector de Limpieza'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                if (barcode.rawValue != null) {
                  _procesarEscaneo(barcode.rawValue!);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigoAccent, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
