import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AppState extends ChangeNotifier {
  String? restauranteId;
  int? mesaSeleccionada;
  List<Map<String, dynamic>> carrito = [];

  bool estaOffline = false;
  late Box _colaSyncBox;
  late Box _pedidosBox;

  AppState() {
    _colaSyncBox = Hive.box('cola_sync');
    _pedidosBox = Hive.box('pedidos');
    _escucharConexion();
  }
  void _escucharConexion() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
      estaOffline = result == ConnectivityResult.none;
      notifyListeners();

      if (!estaOffline) {
        await _sincronizarCola();
      }
    });
  }

  Future<void> _guardarEnCola(String tipo, Map<String, dynamic> datos) async {
      final cola = _colaSyncBox.get('operaciones', defaultValue: []) as List;
      cola.add({'tipo': tipo, 'datos': datos, 'timestamp': DateTime.now().toIso8601String()});
      await _colaSyncBox.put('operaciones', cola);
    }

    Future<void> _sincronizarCola() async {
      final cola = _colaSyncBox.get('operaciones', defaultValue: []) as List;
      if (cola.isEmpty) return;

      for (final operacion in List.from(cola)) {
        try {
          await _ejecutarOperacion(operacion);
          cola.remove(operacion);
          await _colaSyncBox.put('operaciones', cola);
        } catch (e) {
          debugPrint("Fallo al sincronizar operación, se mantiene en cola: $e");
          break;
        }
      }
    }

  Future<void> _ejecutarOperacion(Map operacion) async {
      switch (operacion['tipo']) {
        case 'crear_pedido':
          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(operacion['datos']['restauranteId'])
              .collection('pedidos')
              .doc(operacion['datos']['idLocal'])
              .set(operacion['datos']);
          break;
        case 'crear_notificacion':
          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(operacion['datos']['restauranteId'])
              .collection('notificaciones')
              .add(operacion['datos']);
          break;
      }
    }

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
      final String localId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final pedidoData = {
        'idLocal': localId,
        'restauranteId': restauranteId,
        'mesa': mesaSeleccionada!,
        'pedido': listaFinal,
        'total': totalCarrito,
        'estado': 'pendiente',
        'metodoPago': 'tarjeta',
        'meseroAsignadoId': null,
        'timestamp': DateTime.now(),
      };

      await _pedidosBox.put(localId, pedidoData);
      carrito.clear();
      notifyListeners();      
      
      if (!estaOffline) {
        try {
          pedidoData['timestamp'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(restauranteId)
              .collection('pedidos')
              .doc(localId)
              .set(pedidoData);
          await _pedidosBox.delete(localId);
        } catch (e) {
          await _guardarEnCola('crear_pedido', pedidoData);
        }

      } else {
        await _guardarEnCola('crear_pedido', pedidoData);
      }
      return true;         
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
      final String localId = DateTime.now().millisecondsSinceEpoch.toString();
      final String notifId = 'notif_$localId';

      final pedidoData = {
        'idLocal': localId,
        'restauranteId': restauranteId,
        'mesa': mesaSeleccionada!,
        'pedido': listaFinal,
        'total': totalCarrito,
        'estado': 'esperando_pago',
        'metodoPago': 'efectivo',
        'meseroAsignadoId': null,
        'timestamp': DateTime.now(),
      };

      final notifData = {
        'restauranteId': restauranteId,
        'tipo': 'pago_efectivo',
        'mesa': mesaSeleccionada!,
        'estado': 'pendiente',
        'meseroAsignadoId': null,
        'timestamp': DateTime.now(),
      };

      await _pedidosBox.put(localId, pedidoData);
      carrito.clear();
      notifyListeners();

      if (!estaOffline) {
        try {
          pedidoData['timestamp'] = FieldValue.serverTimestamp();
          notifData['timestamp'] = FieldValue.serverTimestamp();
          
          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(restauranteId)
              .collection('pedidos')
              .doc(localId)
              .set(pedidoData);
              
          final docRef = await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(restauranteId)
              .collection('notificaciones')
              .add(notifData);
              
          await _pedidosBox.delete(localId);
          return docRef.id; // Retorna ID real para escuchar en la pantalla de EsperaPago
        } catch (e) {
          await _guardarEnCola('crear_pedido', pedidoData);
          await _guardarEnCola('crear_notificacion', notifData);
        }
      } else {
        await _guardarEnCola('crear_pedido', pedidoData);
        await _guardarEnCola('crear_notificacion', notifData);
      }
      return notifId; // Retorna ID temporal local para la UI
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
      debugPrint(" FALLO: idDocumento es null");
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
        debugPrint(" FALLO: hay pedidos activos bloqueando la mesa");
        return false;
      }

      await actualizarMesaEnFirebase(numeroMesa, 0);
      debugPrint(" Mesa $numeroMesa actualizada a estado 0");

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
