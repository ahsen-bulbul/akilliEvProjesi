import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/datasources/api_service.dart';

class SetupPackageScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const SetupPackageScreen({super.key, required this.onCompleted});

  @override
  State<SetupPackageScreen> createState() => _SetupPackageScreenState();
}

class _SetupPackageScreenState extends State<SetupPackageScreen> {
  final _cityController = TextEditingController();

  static const _packages = [
    _SetupPackage(
      id: 'studio',
      title: 'Studio',
      subtitle: 'Kompakt ev kurulumu',
      roomCount: 3,
      highlights: ['Salon', 'Mutfak', 'Banyo'],
      icon: Icons.apartment,
    ),
    _SetupPackage(
      id: 'duplex',
      title: 'Dublex',
      subtitle: 'Iki katli ev ve bahce',
      roomCount: 7,
      highlights: ['Alt kat', 'Ust kat', 'Bahce'],
      icon: Icons.holiday_village_outlined,
    ),
    _SetupPackage(
      id: '3_plus_1',
      title: '3+1',
      subtitle: 'Aile evi temel paket',
      roomCount: 6,
      highlights: ['Salon', '3 oda', 'Banyo'],
      icon: Icons.home_work_outlined,
    ),
    _SetupPackage(
      id: '4_plus_1',
      title: '4+1',
      subtitle: 'Genis aile evi',
      roomCount: 8,
      highlights: ['Salon', '4 oda', 'Koridor'],
      icon: Icons.maps_home_work_outlined,
    ),
  ];

  String? _selectedId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _applyPackage() async {
    final selectedId = _selectedId;
    final homeCity = _cityController.text.trim();
    if (selectedId == null) {
      setState(() => _error = 'Bir paket secin.');
      return;
    }
    if (homeCity.isEmpty) {
      setState(() => _error = 'Ev konumu icin sehir girin.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.applySetupPackage(
        packageId: selectedId,
        homeCity: homeCity,
      );
      if (!mounted) {
        return;
      }
      widget.onCompleted();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          children: [
            Text(
              'Ev Paketini Sec',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Odalar, cihazlar ve sensorler secilen plana gore hazirlanacak.',
              style: GoogleFonts.dmSans(
                color: const Color(0xFF8B949E),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cityController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Ev sehri',
                hintText: 'Orn: Trabzon, Istanbul, Ankara',
                prefixIcon: const Icon(Icons.location_city_outlined),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF30363D)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF30363D)),
                ),
              ),
              onChanged: (_) {
                if (_error != null) {
                  setState(() => _error = null);
                }
              },
            ),
            const SizedBox(height: 16),
            for (final package in _packages) ...[
              _PackageCard(
                package: package,
                isSelected: package.id == _selectedId,
                onTap: _saving
                    ? null
                    : () => setState(() {
                        _selectedId = package.id;
                        _error = null;
                      }),
              ),
              const SizedBox(height: 12),
            ],
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: GoogleFonts.dmSans(
                  color: const Color(0xFFFFB4B4),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _applyPackage,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Hazirlaniyor' : 'Paketi Uygula'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: const Color(0xFF06130F),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final _SetupPackage package;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PackageCard({
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xFF00D4AA)
        : const Color(0xFF30363D);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(package.icon, color: const Color(0xFF00D4AA)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          package.title,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${package.roomCount} oda',
                        style: GoogleFonts.spaceMono(
                          color: const Color(0xFF8B949E),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.subtitle,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF8B949E),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final item in package.highlights)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF30363D)),
                          ),
                          child: Text(
                            item,
                            style: GoogleFonts.dmSans(
                              color: const Color(0xFFB7C0CA),
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? const Color(0xFF00D4AA)
                  : const Color(0xFF8B949E),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupPackage {
  final String id;
  final String title;
  final String subtitle;
  final int roomCount;
  final List<String> highlights;
  final IconData icon;

  const _SetupPackage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.roomCount,
    required this.highlights,
    required this.icon,
  });
}
