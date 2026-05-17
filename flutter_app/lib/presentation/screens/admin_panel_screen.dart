import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _deviceNameController = TextEditingController();
  final _deviceTypeController = TextEditingController();
  final _sensorNameController = TextEditingController();
  final _sensorTypeController = TextEditingController();
  final _sensorUnitController = TextEditingController();

  bool _loadingDevices = true;
  bool _loadingSensors = true;
  bool _addingDevice = false;
  bool _addingSensor = false;
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _sensors = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _loadSensors();
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _deviceTypeController.dispose();
    _sensorNameController.dispose();
    _sensorTypeController.dispose();
    _sensorUnitController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() => _loadingDevices = true);
    try {
      final response = await Supabase.instance.client.from('devices').select();
      setState(() {
        _devices = List<Map<String, dynamic>>.from(response as List);
        _loadingDevices = false;
      });
    } catch (e) {
      setState(() {
        _loadingDevices = false;
      });
    }
  }

  Future<void> _loadSensors() async {
    setState(() => _loadingSensors = true);
    try {
      final response = await Supabase.instance.client.from('sensors').select();
      setState(() {
        _sensors = List<Map<String, dynamic>>.from(response as List);
        _loadingSensors = false;
      });
    } catch (e) {
      setState(() {
        _loadingSensors = false;
      });
    }
  }

  Future<void> _addDevice() async {
    final name = _deviceNameController.text.trim();
    final type = _deviceTypeController.text.trim();

    if (name.isEmpty || type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _addingDevice = true);
    try {
      await Supabase.instance.client.from('devices').insert({
        'name': name,
        'device_type': type,
      });

      _deviceNameController.clear();
      _deviceTypeController.clear();
      await _loadDevices();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device başarıyla eklendi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _addingDevice = false);
    }
  }

  Future<void> _addSensor() async {
    final name = _sensorNameController.text.trim();
    final type = _sensorTypeController.text.trim();
    final unit = _sensorUnitController.text.trim();

    if (name.isEmpty || type.isEmpty || unit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _addingSensor = true);
    try {
      await Supabase.instance.client.from('sensors').insert({
        'name': name,
        'sensor_type': type,
        'unit': unit,
      });

      _sensorNameController.clear();
      _sensorTypeController.clear();
      _sensorUnitController.clear();
      await _loadSensors();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sensor başarıyla eklendi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _addingSensor = false);
    }
  }

  Future<void> _deleteDevice(String deviceId) async {
    try {
      await Supabase.instance.client
          .from('devices')
          .delete()
          .eq('id', deviceId);
      await _loadDevices();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device silindi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
    }
  }

  Future<void> _deleteSensor(String sensorId) async {
    try {
      await Supabase.instance.client
          .from('sensors')
          .delete()
          .eq('id', sensorId);
      await _loadSensors();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sensor silindi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          title: const Text('Admin Paneli'),
          backgroundColor: const Color(0xFF0D1117),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Deviceler'),
              Tab(text: 'Sensorler'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildDeviceTab(), _buildSensorTab()]),
      ),
    );
  }

  Widget _buildDeviceTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yeni Device Ekle',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deviceNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                labelText: 'Device Adı',
                labelStyle: const TextStyle(color: Color(0xFF8B949E)),
                hintText: 'ex: Living Room AC',
                hintStyle: const TextStyle(color: Color(0xFF8B949E)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceTypeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                labelText: 'Device Tipi',
                labelStyle: const TextStyle(color: Color(0xFF8B949E)),
                hintText: 'ex: AC, Light, Heater',
                hintStyle: const TextStyle(color: Color(0xFF8B949E)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: const Color(0xFF0D1117),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _addingDevice ? null : _addDevice,
              child: _addingDevice
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Device Ekle'),
            ),
            const SizedBox(height: 32),
            Text(
              'Deviceler',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _loadingDevices
                ? const Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                ? Text(
                    'Henüz device eklenmedi',
                    style: GoogleFonts.dmSans(color: const Color(0xFF8B949E)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return Card(
                        color: const Color(0xFF161B22),
                        child: ListTile(
                          title: Text(
                            device['name'] ?? 'Unknown',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            device['device_type'] ?? 'Unknown Type',
                            style: const TextStyle(color: Color(0xFF8B949E)),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteDevice(device['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yeni Sensor Ekle',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sensorNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                labelText: 'Sensor Adı',
                labelStyle: const TextStyle(color: Color(0xFF8B949E)),
                hintText: 'ex: Living Room Temperature',
                hintStyle: const TextStyle(color: Color(0xFF8B949E)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sensorTypeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                labelText: 'Sensor Tipi',
                labelStyle: const TextStyle(color: Color(0xFF8B949E)),
                hintText: 'ex: Temperature, Humidity, Motion',
                hintStyle: const TextStyle(color: Color(0xFF8B949E)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sensorUnitController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                labelText: 'Birim',
                labelStyle: const TextStyle(color: Color(0xFF8B949E)),
                hintText: 'ex: °C, %, %',
                hintStyle: const TextStyle(color: Color(0xFF8B949E)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00D4AA),
                foregroundColor: const Color(0xFF0D1117),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _addingSensor ? null : _addSensor,
              child: _addingSensor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sensor Ekle'),
            ),
            const SizedBox(height: 32),
            Text(
              'Sensorler',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _loadingSensors
                ? const Center(child: CircularProgressIndicator())
                : _sensors.isEmpty
                ? Text(
                    'Henüz sensor eklenmedi',
                    style: GoogleFonts.dmSans(color: const Color(0xFF8B949E)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sensors.length,
                    itemBuilder: (context, index) {
                      final sensor = _sensors[index];
                      return Card(
                        color: const Color(0xFF161B22),
                        child: ListTile(
                          title: Text(
                            sensor['name'] ?? 'Unknown',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${sensor['sensor_type'] ?? 'Unknown'} (${sensor['unit'] ?? '?'})',
                            style: const TextStyle(color: Color(0xFF8B949E)),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSensor(sensor['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
