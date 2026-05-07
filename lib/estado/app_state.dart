import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  String? restauranteId;
  int? mesaSeleccionada;
  List<Map<String, dynamic>> carrito = [];
  List<Map<String, dynamic>> notificaciones = [];

  void setRestauranteId(String id) {
    restauranteId = id;
    notifyListeners();
  }

  Future<void> actualizarMesaEnFirebase(int index, int nuevoEstado) async {
    String? idDocumento =
        restauranteId ?? FirebaseAuth.instance.currentUser?.uid;

    if (idDocumento == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(idDocumento);
      final doc = await docRef.get();

      if (doc.exists) {
        List<dynamic> mesasFirebase = List.from(doc['mesas']);
        mesasFirebase[index] = nuevoEstado;
        await docRef.update({'mesas': mesasFirebase});
      }
    } catch (e) {
      debugPrint("Error en Firebase: $e");
    }
  }

  void ocuparMesa(int index) async {
    mesaSeleccionada = index;
    carrito.clear();
    await actualizarMesaEnFirebase(index, 1);
    notifyListeners();
  }

  void agregarAlCarrito(Map<String, dynamic> plato) {
    carrito.add(plato);
    notifyListeners();
  }

  int get totalCarrito {
    int total = 0;
    for (var item in carrito) {
      total += item['precio'] as int;
    }
    return total;
  }

  void pagar() async {
    if (mesaSeleccionada != null) {
      int mesaCerrada = mesaSeleccionada!;
      await actualizarMesaEnFirebase(mesaCerrada, 2);

      notificaciones.add({
        'mesa': mesaCerrada + 1,
        'pedido': List<Map<String, dynamic>>.from(carrito),
        'timestamp': DateTime.now(),
      });

      mesaSeleccionada = null;
      carrito.clear();
      notifyListeners();
    }
  }

  void borrarNotificacion(int index) {
    notificaciones.removeAt(index);
    notifyListeners();
  }

  void habilitarMesa(int index) async {
    await actualizarMesaEnFirebase(index, 0);
  }
}

final appState = AppState();
