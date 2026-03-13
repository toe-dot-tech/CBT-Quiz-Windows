import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cbtapp/utils/app_colors.dart';

class TrendChart extends StatefulWidget {
  final List<int> passData;
  final List<int> failData;
  final List<String> labels;

  const TrendChart({
    super.key,
    required this.passData,
    required this.failData,
    required this.labels,
  });

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Performance Trend",
                  // "📈Performance Trend",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildLegendItem(AppColors.pass, "Pass"),
                    const SizedBox(width: 20),
                    _buildLegendItem(AppColors.fail, "Fail"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats summary
            Row(
              children: [
                _buildStatChip(
                  "Avg Pass: ${_calculateAverage(widget.passData)}",
                  AppColors.pass,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  "Avg Fail: ${_calculateAverage(widget.failData)}",
                  AppColors.fail,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  "Peak: ${_findPeak([...widget.passData, ...widget.failData])}",
                  AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main chart
            SizedBox(height: 280, child: _buildChart()),
          ],
        ),
      ),
    );
  }

  // Separate chart widget that rebuilds when data changes
  Widget _buildChart() {
    return LineChart(
      key: ValueKey(widget.passData.length + widget.failData.length),
      mainData(),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(128),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _calculateAverage(List<int> data) {
    if (data.isEmpty) return "0";
    try {
      final sum = data.reduce((a, b) => a + b);
      return (sum / data.length).toStringAsFixed(1);
    } catch (e) {
      return "0";
    }
  }

  int _findPeak(List<int> data) {
    if (data.isEmpty) return 0;
    try {
      return data.reduce((a, b) => a > b ? a : b);
    } catch (e) {
      return 0;
    }
  }

  LineChartData mainData() {
    // Ensure we have valid data
    if (widget.passData.isEmpty || widget.failData.isEmpty) {
      return LineChartData(); // Return empty chart
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.chartGrid.withAlpha(77),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: AppColors.chartGrid.withAlpha(77),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppColors.chartBorder.withAlpha(128)),
      ),
      minX: 0,
      maxX: (widget.labels.length - 1).toDouble(),
      minY: 0,
      maxY: (_findPeak([...widget.passData, ...widget.failData]) + 5)
          .toDouble(),
      lineBarsData: [
        // Pass line
        LineChartBarData(
          spots: _generateSpots(widget.passData),
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.pass,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.pass.withAlpha(77),
                AppColors.pass.withAlpha(0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Fail line
        LineChartBarData(
          spots: _generateSpots(widget.failData),
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.fail,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.fail.withAlpha(77),
                AppColors.fail.withAlpha(0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          // tooltipBgColor: Colors.transparent,
          tooltipPadding: EdgeInsets.zero,
          tooltipMargin: 0,

          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              final isPass = spot.barIndex == 0;
              return LineTooltipItem(
                '${isPass ? '✅ Pass' : '❌ Fail'}: ${spot.y.toInt()}',
                TextStyle(
                  color: isPass ? AppColors.pass : AppColors.fail,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  backgroundColor: Colors.white,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
      ),
    );
  }

  List<FlSpot> _generateSpots(List<int> data) {
    return List.generate(data.length, (index) {
      return FlSpot(index.toDouble(), data[index].toDouble());
    });
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.chartText,
      fontWeight: FontWeight.w500,
      fontSize: 11,
    );

    int index = value.toInt();
    if (index >= 0 && index < widget.labels.length) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(widget.labels[index], style: style),
      );
    }
    return const Text('');
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.chartText,
      fontWeight: FontWeight.w500,
      fontSize: 11,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(value.toInt().toString(), style: style),
    );
  }
}
