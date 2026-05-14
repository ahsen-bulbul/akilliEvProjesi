import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/offline_first_sensor_repository.dart';
import '../../domain/entities/sensor_data.dart';

enum _Metric {
  temperature('Temperature', 'C', Icons.thermostat, Color(0xFFFFB020)),
  humidity('Humidity', '%', Icons.water_drop_outlined, Color(0xFF58A6FF)),
  gas('Gas', 'ppm', Icons.air, Color(0xFF9B59B6)),
  light('Light', 'lx', Icons.light_mode_outlined, Color(0xFFFFD166)),
  distance('Distance', 'cm', Icons.straighten, Color(0xFF00D4AA));

  final String label;
  final String unit;
  final IconData icon;
  final Color color;

  const _Metric(this.label, this.unit, this.icon, this.color);

  double? valueOf(SensorData data) {
    return switch (this) {
      _Metric.temperature => data.temperature,
      _Metric.humidity => data.humidity,
      _Metric.gas => data.gasLevel,
      _Metric.light => data.lightLevel,
      _Metric.distance => data.distanceCm,
    };
  }
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final OfflineFirstSensorRepository _repository =
      OfflineFirstSensorRepository();
  List<SensorData> _history = const [];
  _Metric _selectedMetric = _Metric.temperature;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _repository.getSensorHistory(limit: 200);
      if (!mounted) {
        return;
      }
      setState(() {
        _history = history;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<SensorData> get _displayReadings {
    final now = DateTime.now();
    final today = _readingsForDay(now);
    if (today.isNotEmpty) {
      return today;
    }

    if (_history.isEmpty) {
      return const [];
    }

    final latest = _history
        .map((reading) => reading.createdAt.toLocal())
        .reduce((a, b) => a.isAfter(b) ? a : b);
    return _readingsForDay(latest);
  }

  String get _periodLabel {
    final day = _displayDay;
    if (day == null) {
      return 'No data';
    }

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final date = DateFormat('MMM d, yyyy').format(day);
    if (_isSameDay(day, now)) {
      return 'Today - $date';
    }
    if (_isSameDay(day, yesterday)) {
      return 'Yesterday - $date';
    }
    return date;
  }

  DateTime? get _displayDay {
    final readings = _displayReadings;
    if (readings.isEmpty) {
      return null;
    }
    return readings.first.createdAt.toLocal();
  }

  List<SensorData> _readingsForDay(DateTime day) {
    return _history.where((reading) {
      final local = reading.createdAt.toLocal();
      return _isSameDay(local, day);
    }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool get _isShowingToday {
    final day = _displayDay;
    return day != null && _isSameDay(day, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final readings = _displayReadings;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _StatsHeader(recordCount: readings.length, period: _periodLabel),
              const SizedBox(height: 18),
              if (_loading)
                const _StatsStatus(text: 'Loading daily statistics...')
              else if (_error != null)
                _StatsStatus(text: _error!, isError: true)
              else if (readings.isEmpty)
                const _StatsStatus(
                  text: 'No PostgreSQL or cached sensor records found.',
                )
              else ...[
                if (!_isShowingToday) ...[
                  _StatsStatus(
                    text:
                        'No records found for today. Showing $_periodLabel statistics from history.',
                    isWarning: true,
                  ),
                  const SizedBox(height: 18),
                ],
                _SummaryGrid(readings: readings),
                const SizedBox(height: 18),
                _MetricSelector(
                  selected: _selectedMetric,
                  onSelected: (metric) =>
                      setState(() => _selectedMetric = metric),
                ),
                const SizedBox(height: 14),
                _MetricChart(readings: readings, metric: _selectedMetric),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final int recordCount;
  final String period;

  const _StatsHeader({required this.recordCount, required this.period});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Stats',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$period sensor history',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF8B949E),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Text(
            '$recordCount records',
            style: GoogleFonts.spaceMono(
              color: const Color(0xFF00D4AA),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<SensorData> readings;

  const _SummaryGrid({required this.readings});

  @override
  Widget build(BuildContext context) {
    final summaries = _Metric.values.map((metric) {
      final values = readings.map(metric.valueOf).whereType<double>().toList();
      final average = values.isEmpty
          ? null
          : values.reduce((a, b) => a + b) / values.length;
      return _MetricSummary(metric: metric, average: average);
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: summaries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    summary.metric.icon,
                    color: summary.metric.color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary.metric.label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        summary.average == null
                            ? '--'
                            : summary.average!.toStringAsFixed(1),
                        style: GoogleFonts.spaceMono(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      summary.metric.unit,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricSummary {
  final _Metric metric;
  final double? average;

  const _MetricSummary({required this.metric, required this.average});
}

class _MetricSelector extends StatelessWidget {
  final _Metric selected;
  final ValueChanged<_Metric> onSelected;

  const _MetricSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _Metric.values.map((metric) {
          final isSelected = metric == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(metric.label),
              avatar: Icon(
                metric.icon,
                size: 16,
                color: isSelected ? const Color(0xFF0D1117) : metric.color,
              ),
              selectedColor: metric.color,
              backgroundColor: const Color(0xFF161B22),
              labelStyle: GoogleFonts.dmSans(
                color: isSelected ? const Color(0xFF0D1117) : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected ? metric.color : const Color(0xFF30363D),
              ),
              onSelected: (_) => onSelected(metric),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricChart extends StatelessWidget {
  final List<SensorData> readings;
  final _Metric metric;

  const _MetricChart({required this.readings, required this.metric});

  @override
  Widget build(BuildContext context) {
    final values = readings
        .map(
          (reading) =>
              _ChartPoint(reading.createdAt.toLocal(), metric.valueOf(reading)),
        )
        .where((point) => point.value != null)
        .toList();

    if (values.isEmpty) {
      return const _StatsStatus(text: 'No values found for this metric.');
    }

    final spots = [
      for (var i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), values[i].value!),
    ];
    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final yPadding = ((maxY - minY).abs() * 0.2)
        .clamp(1.0, double.infinity)
        .toDouble();

    return Container(
      height: 290,
      padding: const EdgeInsets.fromLTRB(14, 16, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(metric.icon, color: metric.color, size: 20),
              const SizedBox(width: 8),
              Text(
                '${metric.label} trend',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d').format(DateTime.now()),
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFF8B949E),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY - yPadding,
                maxY: maxY + yPadding,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFF30363D), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF8B949E),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (values.length / 3).clamp(1, 999).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index < 0 || index >= values.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('HH:mm').format(values[index].time),
                            style: GoogleFonts.spaceMono(
                              color: const Color(0xFF8B949E),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: metric.color,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: metric.color.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  final DateTime time;
  final double? value;

  const _ChartPoint(this.time, this.value);
}

class _StatsStatus extends StatelessWidget {
  final String text;
  final bool isError;
  final bool isWarning;

  const _StatsStatus({
    required this.text,
    this.isError = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError
              ? const Color(0xFFFF6B6B)
              : isWarning
              ? const Color(0xFFFFD166)
              : const Color(0xFF30363D),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: isError
              ? const Color(0xFFFFB4B4)
              : isWarning
              ? const Color(0xFFFFD166)
              : const Color(0xFF8B949E),
          fontSize: 13,
        ),
      ),
    );
  }
}
