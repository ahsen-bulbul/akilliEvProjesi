import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _temperature = 22.5;
  double _humidity = 65.0;
  double _airFlow = 12.0;
  bool _isLoading = false;
  Timer? _timer;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _startMockUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMockUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() {
        _temperature = 18 + _rnd.nextDouble() * 18;
        _humidity = 30 + _rnd.nextDouble() * 55;
        _airFlow = 5 + _rnd.nextDouble() * 20;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day} · ${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // --- Üst bar ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF8B949E),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Welcome Home ',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('👋', style: TextStyle(fontSize: 22)),
                        ],
                      ),
                      Text(
                        'Raspberry Pi Smart System',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF8B949E),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF30363D)),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00D4AA),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- Hava durumu kartı ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4AA).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00D4AA).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00D4AA),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LIVE WEATHER',
                                style: GoogleFonts.spaceMono(
                                  color: const Color(0xFF00D4AA),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text('☀️', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Indoor · Living Room',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF8B949E),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _temperature.toStringAsFixed(1),
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            '°C',
                            style: TextStyle(
                              color: Color(0xFF8B949E),
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Partly Cloudy · Outdoor ${(_temperature - 4).toStringAsFixed(0)}°C',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF8B949E),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _weatherStat(
                          '💧',
                          'Humidity',
                          '${_humidity.toStringAsFixed(0)}%',
                        ),
                        const SizedBox(width: 24),
                        _weatherStat(
                          '💨',
                          'Air Flow',
                          '${_airFlow.toStringAsFixed(0)} km/h',
                        ),
                        const SizedBox(width: 24),
                        _weatherStat('☀️', 'UV Index', 'Low'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- Quick Access ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Access',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '3 Sections',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF00D4AA),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _quickAccessCard(
                icon: Icons.sensors,
                color: const Color(0xFF00D4AA),
                title: 'Live Sensors',
                subtitle: 'MQTT real-time data',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _quickAccessCard(
                icon: Icons.tune,
                color: const Color(0xFF9B59B6),
                title: 'Device Control',
                subtitle: 'Lamp, Fan, AC',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _quickAccessCard(
                icon: Icons.bar_chart,
                color: const Color(0xFF3498DB),
                title: 'Statistics',
                subtitle: 'PostgreSQL history',
                onTap: () {},
              ),

              const SizedBox(height: 24),

              // --- Sistem durumu ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.developer_board,
                        color: Color(0xFF00D4AA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'raspi-home-01',
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Mock mode · Supabase connected',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF8B949E),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Online',
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF00D4AA),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weatherStat(String emoji, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: const Color(0xFF8B949E),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _quickAccessCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF8B949E), size: 20),
          ],
        ),
      ),
    );
  }
}
