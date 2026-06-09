import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardAdministrativo extends StatefulWidget {
  const DashboardAdministrativo({super.key});

  @override
  State<DashboardAdministrativo> createState() =>
      _DashboardAdministrativoState();
}

class _DashboardAdministrativoState extends State<DashboardAdministrativo> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final fechaLimite = DateTime.now().subtract(const Duration(days: 30));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Administrativo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurantes')
            .doc(uid)
            .collection('pedidos')
            .where('estado', isEqualTo: 'archivado')
            .where('timestamp', isGreaterThanOrEqualTo: fechaLimite)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pedidos = snapshot.data!.docs;
          if (pedidos.isEmpty) {
            return const Center(
              child: Text('No hay datos en los últimos 30 días.'),
            );
          }

          int totalIngresos = 0;
          Map<String, int> ventasPorPlato = {};
          List<FlSpot> scatterSpots = [];

          for (var doc in pedidos) {
            final data = doc.data() as Map<String, dynamic>;
            final num totalPedido = data['total'] ?? 0;
            totalIngresos += totalPedido.toInt();

            final timestamp = data['timestamp'] as Timestamp?;
            if (timestamp != null) {
              final diasTranscurridos = timestamp
                  .toDate()
                  .difference(fechaLimite)
                  .inDays
                  .toDouble();
              scatterSpots.add(
                FlSpot(diasTranscurridos, totalPedido.toDouble()),
              );
            }

            final items = data['pedido'] as List<dynamic>;
            for (var item in items) {
              String nombre = item['nombre'];
              int cant = item['cantidad'];
              ventasPorPlato[nombre] = (ventasPorPlato[nombre] ?? 0) + cant;
            }
          }

          List<FlSpot> trendlineSpots = [];
          int n = scatterSpots.length;
          if (n > 1) {
            double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
            for (var spot in scatterSpots) {
              sumX += spot.x;
              sumY += spot.y;
              sumXY += spot.x * spot.y;
              sumX2 += spot.x * spot.x;
            }

            double denominador = (n * sumX2) - (sumX * sumX);
            if (denominador != 0) {
              double m = (n * sumXY - sumX * sumY) / denominador;
              double b = (sumY - m * sumX) / n;

              double minX = scatterSpots
                  .map((s) => s.x)
                  .reduce((a, b) => a < b ? a : b);
              double maxX = scatterSpots
                  .map((s) => s.x)
                  .reduce((a, b) => a > b ? a : b);

              trendlineSpots = [
                FlSpot(minX, m * minX + b),
                FlSpot(maxX, m * maxX + b),
              ];
            }
          }

          var platosOrdenados = ventasPorPlato.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          var top5 = platosOrdenados.take(5).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Card(
                    color: Colors.green.shade700,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            'Ingresos (Últimos 30 días)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '\$$totalIngresos',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          const Text(
                            'Dispersión de Ventas y Tendencia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cada punto azul es un pedido. La línea roja muestra la tendencia del consumo.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            height: 220,
                            child: LineChart(
                              LineChartData(
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: scatterSpots,
                                    isCurved: false,
                                    barWidth: 0,
                                    color: Colors.transparent,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter:
                                          (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 5,
                                              color: Colors.indigo,
                                              strokeWidth: 1,
                                              strokeColor:
                                                  Colors.indigo.shade200,
                                            );
                                          },
                                    ),
                                  ),
                                  if (trendlineSpots.isNotEmpty)
                                    LineChartBarData(
                                      spots: trendlineSpots,
                                      isCurved: false,
                                      barWidth: 3,
                                      color: Colors.redAccent,
                                      dotData: const FlDotData(show: false),
                                    ),
                                ],
                                titlesData: FlTitlesData(
                                  show: true,
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 5,
                                      getTitlesWidget: (value, meta) {
                                        DateTime fechaPunto = fechaLimite.add(
                                          Duration(days: value.toInt()),
                                        );
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            DateFormat(
                                              'dd/MM',
                                            ).format(fechaPunto),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: true,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey.shade200,
                                    strokeWidth: 1,
                                  ),
                                  getDrawingVerticalLine: (value) => FlLine(
                                    color: Colors.grey.shade200,
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    left: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (top5.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          children: [
                            const Text(
                              'Top 5 Platos Más Vendidos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 200,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  barGroups: top5.asMap().entries.map((e) {
                                    return BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.value.toDouble(),
                                          color: Colors.indigo,
                                          width: 20,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() >= top5.length) {
                                            return const Text('');
                                          }
                                          String nombre =
                                              top5[value.toInt()].key;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: Text(
                                              nombre.length > 8
                                                  ? '${nombre.substring(0, 8)}...'
                                                  : nombre,
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                  child: Text(
                    'Historial de Pedidos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final data = pedidos[index].data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'] as Timestamp?;
                  final fechaFormateada = timestamp != null
                      ? DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(timestamp.toDate())
                      : 'Fecha desconocida';
                  final items = data['pedido'] as List<dynamic>;
                  final num totalPedido = data['total'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: ExpansionTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(Icons.receipt, color: Colors.white),
                      ),
                      title: Text('Mesa ${data['mesa']} - \$$totalPedido'),
                      subtitle: Text(fechaFormateada),
                      children: items.map((item) {
                        return ListTile(
                          dense: true,
                          title: Text(item['nombre']),
                          trailing: Text(
                            '${item['cantidad']}x  -  \$${(item['precio'] * item['cantidad'])}',
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }, childCount: pedidos.length),
              ),
            ],
          );
        },
      ),
    );
  }
}
