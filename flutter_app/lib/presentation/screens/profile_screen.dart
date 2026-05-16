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
        final dynamic profile = await Supabase.instance.client
            .from('profiles')
            .select('username,avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        if (profile is Map<String, dynamic> && profile.isNotEmpty) {
          _nameController.text = profile['username'] ?? '';
          _avatarUrl = profile['avatar_url'] ?? '';
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

      final data = {
        'id': user.id,
        'username': username,
        if (photoUrl.isNotEmpty) 'avatar_url': photoUrl,
      };

      await Supabase.instance.client.from('profiles').upsert(data);
      setState(() {
        _avatarUrl = photoUrl;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil kaydedildi.')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: const Color(0xFF0D1117),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Hata: $_error', style: GoogleFonts.dmSans(color: Colors.white)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: const Color(0xFF161B22),
                            foregroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                ? NetworkImage(_avatarUrl!)
                                : null,
                            child: _avatarUrl == null || _avatarUrl!.isEmpty
                                ? const Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _email ?? 'Bilinmiyor',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _isAdmin ? 'Admin' : 'Kullanici',
                              style: GoogleFonts.dmSans(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_isEditing) ...
                          [
                            Text(
                              'Ad',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF8B949E),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF161B22),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                hintText: 'Adinizi girin',
                                hintStyle: const TextStyle(color: Color(0xFF8B949E)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Fotoğraf URL',
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF8B949E),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _photoUrlController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFF161B22),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                hintText: 'Resim URL adresi girin',
                                hintStyle: const TextStyle(color: Color(0xFF8B949E)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF00D4AA),
                                      foregroundColor: const Color(0xFF0D1117),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                    ),
                                    onPressed: _saving ? null : _saveProfile,
                                    child: _saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Kaydet'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _isEditing = false),
                                    child: const Text('İptal'),
                                  ),
                                ),
                              ],
                            ),
                          ]
                        else
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4AA),
                              foregroundColor: const Color(0xFF0D1117),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => setState(() => _isEditing = true),
                            child: const Text('Profili Düzenle'),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _signOut,
                          child: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
