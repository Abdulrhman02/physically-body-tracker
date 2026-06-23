import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrendChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> points;
  final String unit;
  final Color color;
  final String title;
  final double height;

  const TrendChart({
    super.key,
    required this.points,
    required this.title,
    this.unit = '',
    this.color = Colors.blue,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            points.isEmpty
                ? 'No data yet'
                : 'Add at least 2 entries to see a trend',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    final spots = [
      for (int i = 0; i < points.length; i++)
        FlSpot(
            points[i].key.millisecondsSinceEpoch.toDouble(), points[i].value),
    ];
    final yMin = points.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final yMax = points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final pad = (yMax - yMin) * 0.15 + 0.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: yMin - pad,
              maxY: yMax + pad,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: ((spots.last.x - spots.first.x) / 4)
                        .clamp(1, double.infinity),
                    getTitlesWidget: (v, _) {
                      final d = DateTime.fromMillisecondsSinceEpoch(v.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(DateFormat('MMM d').format(d),
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: color,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                      show: true, color: color.withValues(alpha: 0.12)),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (items) => items.map((s) {
                    final d = DateTime.fromMillisecondsSinceEpoch(s.x.toInt());
                    return LineTooltipItem(
                      '${DateFormat('MMM d, y').format(d)}\n'
                      '${s.y.toStringAsFixed(1)} $unit',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
