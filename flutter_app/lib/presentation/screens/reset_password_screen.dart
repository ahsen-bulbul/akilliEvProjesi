import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() => _error = 'Sifre en az 6 karakter olmali.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _error = 'Sifreler eslesmiyor.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      await Supabase.instance.client.auth.signOut();
      setState(() {
        _info = 'Sifreniz guncellendi. Yeni sifrenizle giris yapabilirsiniz.';
      });
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_reset,
                    color: Color(0xFF00D4AA),
                    size: 52,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Yeni Sifre',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hesabiniz icin yeni sifre belirleyin',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF8B949E),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _ResetField(
                    controller: _passwordController,
                    label: 'Yeni sifre',
                    icon: Icons.lock_outline,
                    onSubmitted: (_) => _updatePassword(),
                  ),
                  const SizedBox(height: 12),
                  _ResetField(
                    controller: _confirmPasswordController,
                    label: 'Yeni sifre tekrar',
                    icon: Icons.lock_reset,
                    onSubmitted: (_) => _updatePassword(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFFFFB4B4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (_info != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _info!,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF75E6D0),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: const Color(0xFF0D1117),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading ? null : _updatePassword,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sifreyi Guncelle'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => Supabase.instance.client.auth.signOut(),
                    child: const Text('Giris ekranina don'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String>? onSubmitted;

  const _ResetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFF161B22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
      ),
    );
  }
}
