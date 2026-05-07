import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../auth/auth_gate.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_field.dart';
import '../widgets/sponti_logo.dart';
import 'interests_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name     = TextEditingController();
  final _email    = TextEditingController();
  final _password = TextEditingController();
  final _city     = TextEditingController();
  final _phone    = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final phone = _phone.text.trim();

    if (phone.isNotEmpty && !RegExp(r'^\+\d{8,15}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato inválido. Usa +[código de país][número], ej: +56912345678'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final data = <String, dynamic>{
        'name':  _name.text.trim(),
        'email': _email.text.trim(),
        'city':  _city.text.trim(),
        if (phone.isNotEmpty) 'phone': phone,
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(kUserId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Register] Error guardando usuario: $e');
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InterestsScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              const SpontiLogo(fontSize: 26),
              const SizedBox(height: 32),
              const Text(
                'Crea tu\ncuenta.',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 40),
              DarkField(controller: _name, hint: 'Nombre completo'),
              const SizedBox(height: 14),
              DarkField(
                controller: _email,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              DarkField(
                controller: _password,
                hint: 'Contraseña',
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 14),
              DarkField(controller: _city, hint: 'Ciudad'),
              const SizedBox(height: 14),
              DarkField(
                controller: _phone,
                hint: 'Teléfono WhatsApp (ej: +56912345678)',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu número se usa para notificarte cuando un plan se confirma.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Crear cuenta',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 28),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white12)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('o continúa con',
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Colors.white12)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _register,
                  icon: const Text('G',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  label: const Text('Continuar con Google',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: RichText(
                    text: const TextSpan(
                      text: '¿Ya tienes cuenta? ',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Ingresar',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
