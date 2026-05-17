import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _photoUrlController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _isEditing = false;
  String? _error;
  String? _email;
  bool _isAdmin = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      _email = user?.email;

      if (user != null) {
        final profile = await _fetchProfile(user.id);
        if (profile != null) {
          _nameController.text = profile['username']?.toString() ?? '';
          _avatarUrl = profile['avatar_url']?.toString() ?? '';
          _photoUrlController.text = _avatarUrl ?? '';
        }
      }

      final me = await ApiService.getMe();
      setState(() {
        _isAdmin = me.isAdmin;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    try {
      final dynamic profile = await Supabase.instance.client
          .from('profiles')
          .select('username,avatar_url')
          .eq('id', userId)
          .maybeSingle();
      return profile is Map<String, dynamic> ? profile : null;
    } catch (_) {
      final dynamic profile = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .maybeSingle();
      return profile is Map<String, dynamic> ? profile : null;
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw StateError('Kullanici oturumu bulunamadi.');
      }

      final username = _nameController.text.trim();
      final photoUrl = _photoUrlController.text.trim();

      try {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'username': username,
          'avatar_url': photoUrl.isEmpty ? null : photoUrl,
        });
      } catch (_) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'username': username,
        });
      }

      setState(() {
        _avatarUrl = photoUrl;
        _isEditing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil kaydedildi.')));
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  String get _displayName {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      return name;
    }
    final email = _email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'Kullanici';
  }

  String get _initial {
    final source = _displayName.trim();
    if (source.isEmpty) {
      return 'K';
    }
    return source.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(
          'Profil',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D1117),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
              )
            : _error != null
            ? _ErrorPanel(text: _error!, onRetry: _loadProfile)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _ProfileHero(
                    displayName: _displayName,
                    email: _email ?? 'E-posta yok',
                    initial: _initial,
                    avatarUrl: _avatarUrl,
                    isAdmin: _isAdmin,
                  ),
                  const SizedBox(height: 16),
                  _InfoGrid(isAdmin: _isAdmin),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    _EditPanel(
                      nameController: _nameController,
                      photoUrlController: _photoUrlController,
                      saving: _saving,
                      onSave: _saveProfile,
                      onCancel: () => setState(() => _isEditing = false),
                    )
                  else
                    _ActionPanel(
                      onEdit: () => setState(() => _isEditing = true),
                      onSignOut: _signOut,
                    ),
                ],
              ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String displayName;
  final String email;
  final String initial;
  final String? avatarUrl;
  final bool isAdmin;

  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.initial,
    required this.avatarUrl,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final cleanAvatar = avatarUrl?.trim() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00D4AA), width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF12362F),
              foregroundImage: cleanAvatar.isEmpty
                  ? null
                  : NetworkImage(cleanAvatar),
              child: cleanAvatar.isEmpty
                  ? Text(
                      initial,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF75E6D0),
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF8B949E),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAdmin
                          ? const Color(0xFFFFD166)
                          : const Color(0xFF00D4AA),
                    ),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'Kullanici',
                    style: GoogleFonts.spaceMono(
                      color: isAdmin
                          ? const Color(0xFFFFD166)
                          : const Color(0xFF75E6D0),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final bool isAdmin;

  const _InfoGrid({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoTile(
            icon: Icons.verified_user_outlined,
            label: 'Rol',
            value: isAdmin ? 'Admin' : 'Standart',
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _InfoTile(
            icon: Icons.shield_outlined,
            label: 'Oturum',
            value: 'Aktif',
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF00D4AA)),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: const Color(0xFF8B949E),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditPanel extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController photoUrlController;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditPanel({
    required this.nameController,
    required this.photoUrlController,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel('Ad'),
          const SizedBox(height: 8),
          _ProfileTextField(
            controller: nameController,
            hintText: 'Adinizi girin',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 14),
          _FieldLabel('Fotograf URL'),
          const SizedBox(height: 8),
          _ProfileTextField(
            controller: photoUrlController,
            hintText: 'Bos birakirsan ilk harf gorunur',
            icon: Icons.image_outlined,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    foregroundColor: const Color(0xFF0D1117),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: saving ? null : onSave,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Kaydet'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'Iptal',
                onPressed: saving ? null : onCancel,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onSignOut;

  const _ActionPanel({required this.onEdit, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: const Color(0xFF0D1117),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Profili Duzenle'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFB4B4),
              side: const BorderSide(color: Color(0xFFFF6B6B)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Cikis Yap'),
          ),
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;

  const _ProfileTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF8B949E)),
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF00D4AA)),
        ),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF8B949E)),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(color: const Color(0xFF8B949E), fontSize: 13),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFFFB4B4),
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFFFB4B4),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
