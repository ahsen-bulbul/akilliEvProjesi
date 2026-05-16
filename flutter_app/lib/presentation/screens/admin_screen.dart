import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/control_device.dart';
import '../../domain/entities/control_room.dart';
import '../viewmodels/admin_view_model.dart';
import 'chat_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _roomNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadUsers();
    });
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin_chat_fab',
        tooltip: 'Kullanici mesajlari',
        backgroundColor: const Color(0xFF00D4AA),
        foregroundColor: const Color(0xFF06130F),
        onPressed: () {
          final selectedUser = viewModel.selectedUser;
          if (selectedUser == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Once bir kullanici secin.')),
            );
            return;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                targetUserId: selectedUser.id,
                title: 'Destek: ${selectedUser.displayName}',
              ),
            ),
          );
        },
        child: const Icon(Icons.chat),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.loadUsers,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _AdminHeader(onSignOut: Supabase.instance.client.auth.signOut),
              const SizedBox(height: 18),
              if (viewModel.loading)
                const _AdminStatus(text: 'Admin verileri yukleniyor...')
              else if (viewModel.error != null)
                _AdminStatus(text: viewModel.error!, isError: true)
              else if (viewModel.users.isEmpty)
                const _AdminStatus(text: 'Henuz kayitli kullanici yok.')
              else ...[
                _UserSelector(viewModel: viewModel),
                const SizedBox(height: 14),
                _SelectedUserPanel(viewModel: viewModel),
                const SizedBox(height: 14),
                _SummaryStrip(viewModel: viewModel),
                const SizedBox(height: 14),
                _CreateSection(
                  title: 'Oda Ekle',
                  icon: Icons.meeting_room_outlined,
                  saving: viewModel.saving,
                  children: [
                    _AdminTextField(
                      controller: _roomNameController,
                      label: 'Oda adi',
                      icon: Icons.home_outlined,
                    ),
                  ],
                  onSubmit: () async {
                    final name = _roomNameController.text.trim();
                    if (name.isEmpty) {
                      return;
                    }
                    await viewModel.createRoom(name);
                    _roomNameController.clear();
                  },
                ),
                const SizedBox(height: 14),
                _RoomsSection(viewModel: viewModel),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RoomDetailScreen extends StatefulWidget {
  final ControlRoom room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  static const _deviceTypes = ['light', 'fan', 'ac', 'camera', 'door'];
  static const _sensorTypes = [
    'temperature',
    'humidity',
    'gas',
    'soil_moisture',
    'motion',
    'light',
  ];

  final _deviceNameController = TextEditingController();
  final _customDeviceTypeController = TextEditingController();
  final _sensorNameController = TextEditingController();
  final _customSensorTypeController = TextEditingController();
  String _deviceType = _deviceTypes.first;
  String _sensorType = _sensorTypes.first;

  @override
  void dispose() {
    _deviceNameController.dispose();
    _customDeviceTypeController.dispose();
    _sensorNameController.dispose();
    _customSensorTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminViewModel>();
    final devices = viewModel.devicesForRoom(widget.room.id);
    final sensors = viewModel.sensorsForRoom(widget.room.id);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        title: Text(widget.room.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _Panel(
              child: Row(
                children: [
                  const Icon(
                    Icons.meeting_room_outlined,
                    color: Color(0xFF00D4AA),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${devices.length} cihaz · ${sensors.length} sensor',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _CreateSection(
              title: 'Bu Odaya Cihaz Ekle',
              icon: Icons.power_settings_new,
              saving: viewModel.saving,
              children: [
                _AdminTextField(
                  controller: _deviceNameController,
                  label: 'Cihaz adi',
                  icon: Icons.label_outline,
                ),
                const SizedBox(height: 10),
                _AdminComboField(
                  value: _deviceType,
                  values: _deviceTypes,
                  customController: _customDeviceTypeController,
                  label: 'Cihaz tipi',
                  customLabel: 'Ozel cihaz tipi',
                  icon: Icons.category_outlined,
                  onChanged: (value) {
                    setState(() => _deviceType = value);
                    _customDeviceTypeController.clear();
                  },
                ),
              ],
              onSubmit: () async {
                final name = _deviceNameController.text.trim();
                final customType = _customDeviceTypeController.text.trim();
                final type = customType.isEmpty ? _deviceType : customType;
                if (name.isEmpty) {
                  return;
                }
                await viewModel.createDevice(
                  name: name,
                  type: type,
                  roomId: widget.room.id,
                );
                _deviceNameController.clear();
                _customDeviceTypeController.clear();
              },
            ),
            const SizedBox(height: 14),
            _CreateSection(
              title: 'Bu Odaya Sensor Ekle',
              icon: Icons.sensors_outlined,
              saving: viewModel.saving,
              children: [
                _AdminTextField(
                  controller: _sensorNameController,
                  label: 'Sensor adi',
                  icon: Icons.label_outline,
                ),
                const SizedBox(height: 10),
                _AdminComboField(
                  value: _sensorType,
                  values: _sensorTypes,
                  customController: _customSensorTypeController,
                  label: 'Sensor tipi',
                  customLabel: 'Ozel sensor tipi',
                  icon: Icons.category_outlined,
                  onChanged: (value) {
                    setState(() => _sensorType = value);
                    _customSensorTypeController.clear();
                  },
                ),
              ],
              onSubmit: () async {
                final name = _sensorNameController.text.trim();
                final customType = _customSensorTypeController.text.trim();
                final type = customType.isEmpty ? _sensorType : customType;
                if (name.isEmpty) {
                  return;
                }
                await viewModel.createSensor(
                  name: name,
                  type: type,
                  roomId: widget.room.id,
                );
                _sensorNameController.clear();
                _customSensorTypeController.clear();
              },
            ),
            const SizedBox(height: 14),
            _RoomInventorySection(
              title: 'Cihazlar',
              icon: Icons.power_settings_new,
              emptyText: 'Bu odada cihaz yok.',
              children: devices
                  .map(
                    (device) => _DeletableItem(
                      title: device.name,
                      subtitle: device.type,
                      icon: _deviceIcon(device),
                      onDelete: () => viewModel.deleteDevice(device.id),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            _RoomInventorySection(
              title: 'Sensorler',
              icon: Icons.sensors_outlined,
              emptyText: 'Bu odada sensor yok.',
              children: sensors
                  .map(
                    (sensor) => _DeletableItem(
                      title: sensor.name,
                      subtitle: sensor.type,
                      icon: Icons.sensors_outlined,
                      onDelete: () => viewModel.deleteSensor(sensor.id),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _deviceIcon(ControlDevice device) {
    return switch (device.type.toLowerCase()) {
      'light' || 'lamp' => Icons.lightbulb_outline,
      'fan' => Icons.air,
      'ac' || 'climate' => Icons.ac_unit,
      'camera' => Icons.videocam_outlined,
      'door' => Icons.door_front_door_outlined,
      _ => Icons.power_settings_new,
    };
  }
}

class _AdminHeader extends StatelessWidget {
  final Future<void> Function() onSignOut;

  const _AdminHeader({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Panel',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kullanici, oda, cihaz ve sensor yonetimi',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF8B949E),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Cikis yap',
          color: const Color(0xFF00D4AA),
          onPressed: onSignOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    );
  }
}

class _UserSelector extends StatelessWidget {
  final AdminViewModel viewModel;

  const _UserSelector({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: DropdownButtonFormField<String>(
        initialValue: viewModel.selectedUserId,
        dropdownColor: const Color(0xFF161B22),
        decoration: const InputDecoration(
          labelText: 'Yonetilecek kullanici',
          prefixIcon: Icon(Icons.person_outline),
        ),
        items: viewModel.users
            .map(
              (user) => DropdownMenuItem(
                value: user.id,
                child: Text(
                  '${user.displayName}${user.isAdmin ? '  Admin' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            viewModel.selectUser(value);
          }
        },
      ),
    );
  }
}

class _SelectedUserPanel extends StatelessWidget {
  final AdminViewModel viewModel;

  const _SelectedUserPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final user = viewModel.selectedUser;
    if (user == null) {
      return const _AdminStatus(text: 'Once bir kullanici secin.');
    }

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFF00D4AA),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secili Kullanici',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (user.email != null &&
                        user.email != user.displayName) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email!,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFF8B949E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${user.shortId}',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceMono(
                        color: const Color(0xFF6E7681),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: viewModel.saving
                ? null
                : () => _confirmDelete(
                    context,
                    title: 'Kullanici silinsin mi?',
                    message:
                        '${user.displayName} ve kullaniciya ait oda, cihaz, sensor kayitlari silinecek.',
                    onConfirm: viewModel.deleteSelectedUser,
                  ),
            icon: const Icon(Icons.remove_circle_outline),
            label: const Text('Kullaniciyi sil'),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final AdminViewModel viewModel;

  const _SummaryStrip({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryItem(label: 'Oda', value: viewModel.rooms.length),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryItem(label: 'Cihaz', value: viewModel.devices.length),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryItem(label: 'Sensor', value: viewModel.sensors.length),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: GoogleFonts.spaceMono(
              color: const Color(0xFF00D4AA),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: const Color(0xFF8B949E),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomsSection extends StatelessWidget {
  final AdminViewModel viewModel;

  const _RoomsSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined, color: Color(0xFF00D4AA)),
              const SizedBox(width: 10),
              Text(
                'Odalar',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (viewModel.rooms.isEmpty)
            Text(
              'Bu kullanici icin oda yok.',
              style: GoogleFonts.dmSans(
                color: const Color(0xFF8B949E),
                fontSize: 13,
              ),
            )
          else
            for (final room in viewModel.rooms)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoomTile(room: room, viewModel: viewModel),
              ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final ControlRoom room;
  final AdminViewModel viewModel;

  const _RoomTile({required this.room, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final deviceCount = viewModel.devicesForRoom(room.id).length;
    final sensorCount = viewModel.sensorsForRoom(room.id).length;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<AdminViewModel>.value(
              value: viewModel,
              child: RoomDetailScreen(room: room),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.meeting_room_outlined,
              color: Color(0xFF00D4AA),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$deviceCount cihaz · $sensorCount sensor',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF8B949E),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Odayi sil',
              color: const Color(0xFFFFB4B4),
              onPressed: () => _confirmDelete(
                context,
                title: 'Oda silinsin mi?',
                message:
                    '${room.name} odasi ve bu odaya ait cihaz/sensorler silinecek.',
                onConfirm: () => viewModel.deleteRoom(room.id),
              ),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF8B949E)),
          ],
        ),
      ),
    );
  }
}

class _CreateSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool saving;
  final VoidCallback onSubmit;

  const _CreateSection({
    required this.title,
    required this.icon,
    required this.children,
    required this.saving,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00D4AA), size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: saving ? null : onSubmit,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}

class _RoomInventorySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String emptyText;
  final List<Widget> children;

  const _RoomInventorySection({
    required this.title,
    required this.icon,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00D4AA), size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text(
              emptyText,
              style: GoogleFonts.dmSans(
                color: const Color(0xFF8B949E),
                fontSize: 13,
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _DeletableItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Future<void> Function() onDelete;

  const _DeletableItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D4AA), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sil',
            color: const Color(0xFFFFB4B4),
            onPressed: () => _confirmDelete(
              context,
              title: 'Kayit silinsin mi?',
              message: '$title silinecek.',
              onConfirm: onDelete,
            ),
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      title: Text(title, style: GoogleFonts.dmSans(color: Colors.white)),
      content: Text(
        message,
        style: GoogleFonts.dmSans(color: const Color(0xFF8B949E)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Vazgec'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sil'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await onConfirm();
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _AdminComboField extends StatelessWidget {
  final String value;
  final List<String> values;
  final TextEditingController customController;
  final String label;
  final String customLabel;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _AdminComboField({
    required this.value,
    required this.values,
    required this.customController,
    required this.label,
    required this.customLabel,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: const Color(0xFF161B22),
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          items: values
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: customController,
          decoration: InputDecoration(
            labelText: customLabel,
            prefixIcon: const Icon(Icons.edit_outlined),
            helperText: 'Bos birakilirsa secili tip kullanilir',
            helperStyle: GoogleFonts.dmSans(
              color: const Color(0xFF8B949E),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: child,
    );
  }
}

class _AdminStatus extends StatelessWidget {
  final String text;
  final bool isError;

  const _AdminStatus({required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: isError ? const Color(0xFFFFB4B4) : const Color(0xFF8B949E),
          fontSize: 13,
        ),
      ),
    );
  }
}
