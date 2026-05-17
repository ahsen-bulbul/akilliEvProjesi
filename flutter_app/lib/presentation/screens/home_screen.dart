import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/api_service.dart';
import 'profile_screen.dart';
import 'admin_panel_screen.dart';
import '../viewmodels/sensor_view_model.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onQuickAccessSelected;

  const HomeScreen({super.key, this.onQuickAccessSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherData? _weather;
  bool _isWeatherLoading = true;
  String? _weatherError;
  Timer? _weatherTimer;
  Timer? _statusTimer;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadAdminStatus();
    _weatherTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _loadWeather(),
    );
    _statusTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadAdminStatus() async {
    try {
      final me = await ApiService.getMe();
      if (mounted) {
        setState(() {
          _isAdmin = me.isAdmin;
        });
        if (!_isAdmin) {
          debugPrint('Current user is NOT admin. Admin status: ${me.isAdmin}');
        }
      }
    } catch (e) {
      debugPrint('Error loading admin status: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Admin status error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    if (_weather == null) {
      setState(() {
        _isWeatherLoading = true;
        _weatherError = null;
      });
    }

    try {
      final weather = await ApiService.getCurrentWeather();
      if (!mounted) return;
      setState(() {
        _weather = weather;
        _isWeatherLoading = false;
        _weatherError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isWeatherLoading = false;
        _weatherError = 'Hava durumu alinamadi';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorViewModel = context.watch<SensorViewModel>();
    final raspberryStatus = _raspberryStatus(sensorViewModel);
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isAdmin)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminPanelScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF161B22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF30363D),
                              ),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings,
                              color: Color(0xFF00D4AA),
                              size: 22,
                            ),
                          ),
                        ),
                      if (_isAdmin) const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF161B22),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF30363D),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline,
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
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _loadAdminStatus,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Color(0xFF8B949E),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Profil',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hesabini ve admin durumunu görüntüle.',
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF8B949E),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF8B949E),
                        size: 18,
                      ),
                    ],
                  ),
                ),
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
                            color: const Color(
                              0xFF00D4AA,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(
                                0xFF00D4AA,
                              ).withValues(alpha: 0.3),
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
                        Text(
                          _weatherIcon(_weather),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _weather == null
                          ? 'Ev konumu'
                          : 'Ev konumu · ${_weather!.location}',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF8B949E),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_isWeatherLoading)
                          const SizedBox(
                            width: 34,
                            height: 34,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF00D4AA),
                            ),
                          )
                        else
                          Text(
                            _weather?.temperature.toStringAsFixed(1) ?? '--',
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
                      _weatherSubtitle,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF8B949E),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _weatherStat(
                          '💧',
                          'Humidity',
                          _formatPercent(_weather?.humidity),
                        ),
                        _weatherStat(
                          '💨',
                          'Wind',
                          _formatSpeed(_weather?.windSpeed),
                        ),
                        _weatherStat(
                          '🌡️',
                          'Feels Like',
                          _formatTemperature(_weather?.apparentTemperature),
                        ),
                        _weatherStat(
                          '☀️',
                          'UV Max',
                          _formatUv(_weather?.uvIndex),
                        ),
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
                    '4 Sections',
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
                subtitle: 'MQTT stream and latest values',
                onTap: () => widget.onQuickAccessSelected?.call(1),
              ),
              const SizedBox(height: 10),
              _quickAccessCard(
                icon: Icons.tune,
                color: const Color(0xFF9B59B6),
                title: 'Device Control',
                subtitle: 'Lamp, Fan, AC',
                onTap: () => widget.onQuickAccessSelected?.call(2),
              ),
              const SizedBox(height: 10),
              _quickAccessCard(
                icon: Icons.bar_chart,
                color: const Color(0xFF3498DB),
                title: 'Statistics',
                subtitle: 'Sensor history and trends',
                onTap: () => widget.onQuickAccessSelected?.call(3),
              ),
              const SizedBox(height: 10),
              _quickAccessCard(
                icon: Icons.videocam,
                color: const Color(0xFFE67E22),
                title: 'Cameras',
                subtitle: 'Security camera feeds',
                onTap: () => widget.onQuickAccessSelected?.call(4),
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
                        color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.developer_board,
                        color: Color(0xFF00D4AA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
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
                            raspberryStatus.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFF8B949E),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: raspberryStatus.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        raspberryStatus.label,
                        style: GoogleFonts.dmSans(
                          color: raspberryStatus.color,
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

  _RaspberryStatus _raspberryStatus(SensorViewModel viewModel) {
    final latest = viewModel.latest;
    if (viewModel.loading && latest == null) {
      return const _RaspberryStatus(
        label: 'Waiting',
        subtitle: 'MQTT live data bekleniyor',
        color: Color(0xFFFFB020),
      );
    }

    if (latest == null) {
      return const _RaspberryStatus(
        label: 'Offline',
        subtitle: 'MQTT verisi alinmadi',
        color: Color(0xFFE74C3C),
      );
    }

    if (viewModel.showingCachedData) {
      return _RaspberryStatus(
        label: 'Cached',
        subtitle: 'Canli MQTT yok · Son veri ${_timeAgo(latest.createdAt)}',
        color: const Color(0xFFFFB020),
      );
    }

    final age = DateTime.now().difference(latest.createdAt.toLocal());
    if (age <= const Duration(seconds: 30)) {
      return _RaspberryStatus(
        label: 'Online',
        subtitle: 'Canli MQTT · Son veri ${_timeAgo(latest.createdAt)}',
        color: const Color(0xFF00D4AA),
      );
    }

    return _RaspberryStatus(
      label: 'Offline',
      subtitle: 'MQTT akisi durdu · Son veri ${_timeAgo(latest.createdAt)}',
      color: const Color(0xFFE74C3C),
    );
  }

  String _timeAgo(DateTime value) {
    final age = DateTime.now().difference(value.toLocal());
    if (age.inSeconds < 5) return 'simdi';
    if (age.inSeconds < 60) return '${age.inSeconds} sn once';
    if (age.inMinutes < 60) return '${age.inMinutes} dk once';
    if (age.inHours < 24) return '${age.inHours} sa once';
    return '${age.inDays} gun once';
  }

  String get _weatherSubtitle {
    if (_weatherError != null) return _weatherError!;
    final weather = _weather;
    if (weather == null) return 'Gercek hava durumu yukleniyor';
    final feelsLike = weather.apparentTemperature == null
        ? null
        : 'Hissedilen ${weather.apparentTemperature!.toStringAsFixed(0)}°C';
    return [weather.condition, feelsLike].whereType<String>().join(' · ');
  }

  String _formatPercent(double? value) {
    return value == null ? '--' : '${value.toStringAsFixed(0)}%';
  }

  String _formatSpeed(double? value) {
    return value == null ? '--' : '${value.toStringAsFixed(0)} km/h';
  }

  String _formatTemperature(double? value) {
    return value == null ? '--' : '${value.toStringAsFixed(0)}°C';
  }

  String _formatUv(double? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(1);
  }

  String _weatherIcon(WeatherData? weather) {
    final code = weather?.weatherCode;
    if (code == null) return '☁️';
    if (code == 0) return weather?.isDay == false ? '🌙' : '☀️';
    if ({1, 2, 3, 45, 48}.contains(code)) return '☁️';
    if ({51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82}.contains(code)) {
      return '🌧️';
    }
    if ({71, 73, 75, 77, 85, 86}.contains(code)) return '❄️';
    if ({95, 96, 99}.contains(code)) return '⛈️';
    return '🌤️';
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
                color: color.withValues(alpha: 0.15),
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

class _RaspberryStatus {
  final String label;
  final String subtitle;
  final Color color;

  const _RaspberryStatus({
    required this.label,
    required this.subtitle,
    required this.color,
  });
}
