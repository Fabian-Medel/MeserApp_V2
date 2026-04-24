import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  //Estado de uan mesa (libre, ocupada, limpiando)
  List<int> mesas = [0, 0, 0, 0, 0, 0];

  int? mesaSeleccionada;

  List<Map<String, dynamic>> notificaciones = [];

  //Menu predeterminado
  final List<Map<String, dynamic>> menu = [
    {'nombre': 'Pizza Mechada', 'precio': 14000, 'icono': Icons.local_pizza},
    {
      'nombre': 'Hamburguesa Casera',
      'precio': 9500,
      'icono': Icons.lunch_dining,
    },
    {'nombre': 'Tabla Sushi (12p)', 'precio': 11000, 'icono': Icons.set_meal},
    {'nombre': 'Limonada Menta', 'precio': 3500, 'icono': Icons.local_drink},
  ];

  List<Map<String, dynamic>> carrito = [];

  //Validacion de usuario y clave staff
  bool loginStaff(String user, String pass) {
    return user == 'admin' && pass == '1234';
  }

  //Funcion para añadir pedido al carrito
  void agregarAlCarrito(Map<String, dynamic> plato) {
    carrito.add(plato);
    notifyListeners();
  }

  //Funcion para calcular el valor total
  int get totalCarrito {
    int total = 0;
    for (var item in carrito) {
      total += item['precio'] as int;
    }
    return total;
  }

  //Funcion para cambiar el estado de una mesa a ocupada
  void ocuparMesa(int index) {
    mesas[index] = 1;
    mesaSeleccionada = index;
    carrito.clear();
    notifyListeners();
  }

  //Funcion para pagar
  void pagar() {
    if (mesaSeleccionada != null) {
      mesas[mesaSeleccionada!] = 2; //cambia el estado de la mesa a "limpiando"

      notificaciones.add({
        'mesa': mesaSeleccionada! + 1,
        'pedido': List<Map<String, dynamic>>.from(carrito),
        'timestamp': DateTime.now(),
      });

      mesaSeleccionada = null;
      carrito.clear();
      notifyListeners();
    }
  }

  //Funcion para borrar una notificacion
  void borrarNotificacion(int index) {
    notificaciones.removeAt(index);
    notifyListeners();
  }

  //Funcion para habilitar mesa
  void habilitarMesa(int index) {
    mesas[index] = 0; //Cambia el estado de una mesa a "libre"
    notifyListeners();
  }
}

final appState = AppState();
