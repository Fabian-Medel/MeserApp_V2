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
      cola.add({'tipo': tipo, 'datos': datos, 'timestamp': DateTime.now().millisecondsSinceEpoch});
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
      
      final Map<String, dynamic> datosFirebase = Map<String, dynamic>.from(operacion['datos']);
      
      if (datosFirebase['timestampEpoch'] != null) {
        datosFirebase['timestamp'] = Timestamp.fromMillisecondsSinceEpoch(datosFirebase['timestampEpoch']);
        datosFirebase.remove('timestampEpoch');
      }
      
      final String docId = datosFirebase['idLocal'] ?? '';

      switch (operacion['tipo']) {
        case 'crear_pedido':
          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(operacion['datos']['restauranteId'])
              .collection('pedidos')
              .doc(docId)
              .set(datosFirebase);
          break;
        case 'crear_notificacion':
          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(datosFirebase['restauranteId'])
              .collection('notificaciones')
              .doc(docId)
              .set(datosFirebase);
          break;
        case 'actualizar_mesa':
          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(datosFirebase['restauranteId'])
              .collection('mesas')
              .doc(docId)
              .update({'estado': datosFirebase['estado']});
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
    final datosMesa = {
      'restauranteId': idDocumento,
      'idLocal': '$numeroMesa',
      'estado': nuevoEstado,
    };

    if (!estaOffline) {
      try {
        await FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(idDocumento)
            .collection('mesas')
            .doc('$numeroMesa')
            .update({'estado': nuevoEstado});
      } catch (e) {
        await _guardarEnCola('actualizar_mesa', datosMesa);
      }
    } else {
      await _guardarEnCola('actualizar_mesa', datosMesa);
    }
  }

  void ocuparMesa(int numeroMesa) async {
    mesaSeleccionada = numeroMesa;
    carrito.clear();
    await actualizarMesaEnFirebase(numeroMesa, 1);

    if (restauranteId != null && !estaOffline) {
      try {
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
      } catch (e) {
        debugPrint("Error al archivar pedidos viejos en modo offline/inestable: $e");
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
      final listaFinal = _agruparCarrito();
      final String localId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final Map<String, dynamic> pedidoData = {
        'idLocal': localId,
        'restauranteId': restauranteId,
        'mesa': mesaSeleccionada!,
        'pedido': listaFinal,
        'total': totalCarrito,
        'estado': 'pendiente',
        'metodoPago': 'tarjeta',
        'meseroAsignadoId': null,
        'timestampEpoch': DateTime.now().millisecondsSinceEpoch,
      };

      await _pedidosBox.put(localId, pedidoData);
      carrito.clear();
      notifyListeners();      
      
      if (!estaOffline) {
        try {
          final Map<String, dynamic> datosDirectos = Map<String, dynamic>.from(pedidoData);
          datosDirectos['timestamp'] = FieldValue.serverTimestamp();
          datosDirectos.remove('timestampEpoch');

          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(restauranteId)
              .collection('pedidos')
              .doc(localId)
              .set(datosDirectos);

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
      final listaFinal = _agruparCarrito();
      final String localId = DateTime.now().millisecondsSinceEpoch.toString();
      final String notifId = 'notif_$localId'; 

      final Map<String, dynamic> pedidoData = {
        'idLocal': localId,
        'restauranteId': restauranteId,
        'mesa': mesaSeleccionada!,
        'pedido': listaFinal,
        'total': totalCarrito,
        'estado': 'esperando_pago',
        'metodoPago': 'efectivo',
        'meseroAsignadoId': null,
        'timestampEpoch': DateTime.now().millisecondsSinceEpoch,
      };

      final Map<String, dynamic> notifData = {
        'idLocal': notifId,
        'restauranteId': restauranteId,
        'tipo': 'pago_efectivo',
        'mesa': mesaSeleccionada!,
        'estado': 'pendiente',
        'meseroAsignadoId': null,
        'timestampEpoch': DateTime.now().millisecondsSinceEpoch,
      };

      await _pedidosBox.put(localId, pedidoData);
      carrito.clear();
      notifyListeners();

      if (!estaOffline) {
        try {
          final Map<String, dynamic> pDirecto = Map<String, dynamic>.from(pedidoData);
          final Map<String, dynamic> nDirecto = Map<String, dynamic>.from(notifData);
          pDirecto['timestamp'] = FieldValue.serverTimestamp();
          nDirecto['timestamp'] = FieldValue.serverTimestamp();
          pDirecto.remove('timestampEpoch');
          nDirecto.remove('timestampEpoch');

          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(restauranteId)
              .collection('pedidos')
              .doc(localId)
              .set(pDirecto);
              
          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(restauranteId)
              .collection('notificaciones')
              .doc(notifId)
              .set(nDirecto);

          await _pedidosBox.delete(localId);
          return notifId; 
        } catch (e) {
          await _guardarEnCola('crear_pedido', pedidoData);
          await _guardarEnCola('crear_notificacion', notifData);
        }
      } else {
        await _guardarEnCola('crear_pedido', pedidoData);
        await _guardarEnCola('crear_notificacion', notifData);
      }
      return notifId;
    }
    return null;
  }

  Future<String?> solicitarAsistencia({String tipo = 'asistencia'}) async {
    if (mesaSeleccionada != null && restauranteId != null) {
      final String localId = 'asist_${DateTime.now().millisecondsSinceEpoch}';
      
      final Map<String, dynamic> notifData = {
        'idLocal': localId,
        'restauranteId': restauranteId,
        'tipo': tipo,
        'mesa': mesaSeleccionada!,
        'estado': 'pendiente',
        'meseroAsignadoId': null,
        'timestampEpoch': DateTime.now().millisecondsSinceEpoch,
      };

      if (!estaOffline) {
        try {
          final Map<String, dynamic> nDirecto = Map<String, dynamic>.from(notifData);
          nDirecto['timestamp'] = FieldValue.serverTimestamp();
          nDirecto.remove('timestampEpoch');

          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(restauranteId)
              .collection('notificaciones')
              .doc(localId)
              .set(nDirecto);
          return localId;
        } catch (e) {
          await _guardarEnCola('crear_notificacion', notifData);
        }
      } else {
        await _guardarEnCola('crear_notificacion', notifData);
      }
      return localId;
    }
    return null;
  }


  Future<void> solicitarLimpieza() async {
    if (mesaSeleccionada != null && restauranteId != null) {
      int mesaCerrada = mesaSeleccionada!;
      final String localId = 'limp_${DateTime.now().millisecondsSinceEpoch}';

      if (!estaOffline) {
        try {
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
        } catch (e) {
          debugPrint("Error limpiando órdenes de mesa de forma síncrona: $e");
        }
      }

      await actualizarMesaEnFirebase(mesaCerrada, 2);

      final Map<String, dynamic> notifData = {
        'idLocal': localId,
        'restauranteId': restauranteId,
        'tipo': 'limpieza',
        'mesa': mesaCerrada,
        'estado': 'pendiente',
        'meseroAsignadoId': null,
        'timestampEpoch': DateTime.now().millisecondsSinceEpoch,
      };

      if (!estaOffline) {
        try {
          final Map<String, dynamic> nDirecto = Map<String, dynamic>.from(notifData);
          nDirecto['timestamp'] = FieldValue.serverTimestamp();
          nDirecto.remove('timestampEpoch');

          await FirebaseFirestore.instance
              .collection('restaurantes')
              .doc(restauranteId)
              .collection('notificaciones')
              .doc(localId)
              .set(nDirecto);
        } catch (e) {
          await _guardarEnCola('crear_notificacion', notifData);
        }
      } else {
        await _guardarEnCola('crear_notificacion', notifData);
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
    final String? idDocumento = restauranteId ?? FirebaseAuth.instance.currentUser?.uid;
    if (idDocumento == null) return false;

    try {
      await actualizarMesaEnFirebase(numeroMesa, 0);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error al habilitar mesa: $e");
      return false;
    }
  }

  List<Map<String, dynamic>> _agruparCarrito() {
    final carritoAgrupado = <String, Map<String, dynamic>>{};
    for (var item in carrito) {
      if (carritoAgrupado.containsKey(item['nombre'])) {
        carritoAgrupado[item['nombre']]!['cantidad'] += 1;
      } else {
        carritoAgrupado[item['nombre']] = {
          'nombre': item['nombre'],
          'precio': item['precio'],
          'cantidad': 1,
          'urlImagen': item['urlImagen'],
          'descripcion': item['descripcion'],
          'tiempo': item['tiempo']
        };
      }
    }
    return carritoAgrupado.values.toList();
  }
}

final appState = AppState();