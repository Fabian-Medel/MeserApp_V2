import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppState extends ChangeNotifier {
  String? restauranteId;
  int? mesaSeleccionada;
  List<Map<String, dynamic>> carrito = [];

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

  Future<void> enviarPedidoCocina() async {
    if (mesaSeleccionada != null && restauranteId != null) {
      int numeroMesa = mesaSeleccionada! + 1;

      final carritoAgrupado = <String, Map<String, dynamic>>{};
      for (var item in carrito) {
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

      try {
        await FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(restauranteId)
            .collection('pedidos')
            .add({
              'mesa': numeroMesa,
              'pedido': listaFinal,
              'total': totalCarrito,
              'estado': 'pendiente',
              'meseroAsignadoId': null,
              'timestamp': FieldValue.serverTimestamp(),
            });

        carrito.clear();
        notifyListeners();
      } catch (e) {
        debugPrint("Error al enviar pedido: $e");
      }
    }
  }

  Future<void> solicitarAsistencia() async {
    if (mesaSeleccionada != null && restauranteId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(restauranteId)
            .collection('notificaciones')
            .add({
              'tipo': 'asistencia',
              'mesa': mesaSeleccionada! + 1,
              'estado': 'pendiente',
              'meseroAsignadoId': null,
              'timestamp': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint("Error al enviar asistencia: $e");
      }
    }
  }

  Future<void> solicitarLimpieza() async {
    if (mesaSeleccionada != null && restauranteId != null) {
      int mesaCerrada = mesaSeleccionada!;
      await actualizarMesaEnFirebase(mesaCerrada, 2);

      try {
        await FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(restauranteId)
            .collection('notificaciones')
            .add({
              'tipo': 'limpieza',
              'mesa': mesaCerrada + 1,
              'estado': 'pendiente',
              'meseroAsignadoId': null,
              'timestamp': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint("Error al enviar notificación de limpieza: $e");
      }

      mesaSeleccionada = null;
      carrito.clear();
      restauranteId = null;
      notifyListeners();
    }
  }

  void habilitarMesa(int index) async {
    await actualizarMesaEnFirebase(index, 0);

    if (restauranteId != null) {
      final batch = FirebaseFirestore.instance.batch();

      final pedidosSnap = await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(restauranteId)
          .collection('pedidos')
          .where('mesa', isEqualTo: index + 1)
          .get();

      for (var doc in pedidosSnap.docs) {
        if (doc.data()['estado'] != 'archivado') {
          batch.update(doc.reference, {'estado': 'archivado'});
        }
      }

      final notifSnap = await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(restauranteId)
          .collection('notificaciones')
          .where('mesa', isEqualTo: index + 1)
          .get();

      for (var doc in notifSnap.docs) {
        if (doc.data()['estado'] != 'archivado') {
          batch.update(doc.reference, {'estado': 'archivado'});
        }
      }
      await batch.commit();
    }
    notifyListeners();
  }
}

final appState = AppState();
