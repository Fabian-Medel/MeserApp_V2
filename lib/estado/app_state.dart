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

  Future<void> actualizarMesaEnFirebase(int numeroMesa, int nuevoEstado) async {
    String? idDocumento =
        restauranteId ?? FirebaseAuth.instance.currentUser?.uid;
    if (idDocumento == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(idDocumento)
          .collection('mesas')
          .doc('$numeroMesa')
          .update({'estado': nuevoEstado});
    } catch (e) {
      debugPrint("Error en Firebase al actualizar mesa $numeroMesa: $e");
    }
  }

  void ocuparMesa(int numeroMesa) async {
    mesaSeleccionada = numeroMesa;
    carrito.clear();
    await actualizarMesaEnFirebase(numeroMesa, 1);

    if (restauranteId != null) {
      final pedidosViejos = await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(restauranteId)
          .collection('pedidos')
          .where('mesa', isEqualTo: numeroMesa)
          .get();

      if (pedidosViejos.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in pedidosViejos.docs) {
          if (doc.data()['estado'] != 'archivado') {
            batch.update(doc.reference, {'estado': 'archivado'});
          }
        }
        await batch.commit();
      }
    }
    notifyListeners();
  }

  void agregarAlCarrito(Map<String, dynamic> plato) {
    carrito.add(plato);
    notifyListeners();
  }

  void eliminarDelCarrito(String nombrePlato) {
    final index = carrito.lastIndexWhere(
      (item) => item['nombre'] == nombrePlato,
    );
    if (index != -1) {
      carrito.removeAt(index);
      notifyListeners();
    }
  }

  int cantidadEnCarrito(String nombrePlato) {
    return carrito.where((item) => item['nombre'] == nombrePlato).length;
  }

  int get totalCarrito {
    int total = 0;
    for (var item in carrito) {
      total += item['precio'] as int;
    }
    return total;
  }

  // --- NUEVO: PAGO CON TARJETA (Directo a cocina) ---
  Future<bool> enviarPedidoTarjeta() async {
    if (mesaSeleccionada != null && restauranteId != null) {
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
              'mesa': mesaSeleccionada!,
              'pedido': listaFinal,
              'total': totalCarrito,
              'estado': 'pendiente', // Va directo al chef
              'metodoPago': 'tarjeta',
              'meseroAsignadoId': null,
              'timestamp': FieldValue.serverTimestamp(),
            });

        carrito.clear();
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint("Error al enviar pedido con tarjeta: $e");
        return false;
      }
    }
    return false;
  }

  Future<String?> enviarPedidoEfectivo() async {
    if (mesaSeleccionada != null && restauranteId != null) {
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
              'mesa': mesaSeleccionada!,
              'pedido': listaFinal,
              'total': totalCarrito,
              'estado': 'esperando_pago',
              'metodoPago': 'efectivo',
              'meseroAsignadoId': null,
              'timestamp': FieldValue.serverTimestamp(),
            });

        final docRef = await FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(restauranteId)
            .collection('notificaciones')
            .add({
              'tipo': 'pago_efectivo',
              'mesa': mesaSeleccionada!,
              'estado': 'pendiente',
              'meseroAsignadoId': null,
              'timestamp': FieldValue.serverTimestamp(),
            });

        carrito.clear();
        notifyListeners();
        return docRef.id;
      } catch (e) {
        debugPrint("Error al generar pago en efectivo: $e");
        return null;
      }
    }
    return null;
  }

  Future<String?> solicitarAsistencia({String tipo = 'asistencia'}) async {
    if (mesaSeleccionada != null && restauranteId != null) {
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(restauranteId)
            .collection('notificaciones')
            .add({
              'tipo': tipo,
              'mesa': mesaSeleccionada!,
              'estado': 'pendiente',
              'meseroAsignadoId': null,
              'timestamp': FieldValue.serverTimestamp(),
            });
        return docRef.id;
      } catch (e) {
        debugPrint("Error al enviar asistencia: $e");
        return null;
      }
    }
    return null;
  }

  Future<void> solicitarLimpieza() async {
    if (mesaSeleccionada != null && restauranteId != null) {
      int mesaCerrada = mesaSeleccionada!;

      final pedidosActivos = await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(restauranteId)
          .collection('pedidos')
          .where('mesa', isEqualTo: mesaCerrada)
          .where('estado', whereIn: ['pendiente', 'preparando', 'listo'])
          .get();

      if (pedidosActivos.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in pedidosActivos.docs) {
          batch.update(doc.reference, {'estado': 'archivado'});
        }
        await batch.commit();
      }

      await actualizarMesaEnFirebase(mesaCerrada, 2);

      try {
        await FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(restauranteId)
            .collection('notificaciones')
            .add({
              'tipo': 'limpieza',
              'mesa': mesaCerrada,
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

  void abandonarMesaVirtual() {
    if (mesaSeleccionada != null && restauranteId != null) {
      actualizarMesaEnFirebase(mesaSeleccionada!, 0);
      mesaSeleccionada = null;
      carrito.clear();
      restauranteId = null;
      notifyListeners();
    }
  }

  Future<bool> habilitarMesa(int numeroMesa) async {
    final String? idDocumento =
        restauranteId ?? FirebaseAuth.instance.currentUser?.uid;

    debugPrint("=== habilitarMesa ===");
    debugPrint("restauranteId: $restauranteId");
    debugPrint("uid auth: ${FirebaseAuth.instance.currentUser?.uid}");
    debugPrint("idDocumento final: $idDocumento");

    if (idDocumento == null) {
      debugPrint("❌ FALLO: idDocumento es null");
      return false;
    }

    try {
      final pedidosPendientes = await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(idDocumento)
          .collection('pedidos')
          .where('mesa', isEqualTo: numeroMesa)
          .where('estado', whereIn: ['pendiente', 'preparando', 'listo'])
          .get();

      debugPrint(
        "Pedidos pendientes encontrados: ${pedidosPendientes.docs.length}",
      );

      if (pedidosPendientes.docs.isNotEmpty) {
        debugPrint("❌ FALLO: hay pedidos activos bloqueando la mesa");
        return false;
      }

      await actualizarMesaEnFirebase(numeroMesa, 0);
      debugPrint("✅ Mesa $numeroMesa actualizada a estado 0");

      final batch = FirebaseFirestore.instance.batch();

      final pedidosSnap = await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(idDocumento)
          .collection('pedidos')
          .where('mesa', isEqualTo: numeroMesa)
          .get();

      for (var doc in pedidosSnap.docs) {
        if (doc.data()['estado'] != 'archivado') {
          batch.update(doc.reference, {'estado': 'archivado'});
        }
      }

      final notifSnap = await FirebaseFirestore.instance
          .collection('restaurantes')
          .doc(idDocumento)
          .collection('notificaciones')
          .where('mesa', isEqualTo: numeroMesa)
          .get();

      for (var doc in notifSnap.docs) {
        if (doc.data()['estado'] != 'archivado') {
          batch.update(doc.reference, {'estado': 'archivado'});
        }
      }

      await batch.commit();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error al habilitar mesa: $e");
      return false;
    }
  }
}

final appState = AppState();
