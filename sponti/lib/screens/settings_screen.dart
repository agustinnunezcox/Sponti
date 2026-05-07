import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth_gate.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_field.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Profile
  final _nameCtrl  = TextEditingController();
  final _cityCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _savingProfile  = false;
  bool _savingPhone    = false;
  bool _savingInterests = false;
  bool _loadingUser    = true;

  // Interests
  Set<String> _selectedInterests = {};

  // Prefs
  bool   _notifications = true;
  String _language      = 'Español';

  // All available interests (same as onboarding)
  static const _allInterests = [
    ('Fútbol',   '⚽'), ('Música',   '🎵'), ('Drinks',   '🍺'),
    ('Surf',     '🏄'), ('Comer',    '🌮'), ('Tenis',    '🎾'),
    ('Teatro',   '🎭'), ('Aventura', '🏕️'), ('Padel',    '🏓'),
    ('Golf',     '⛳'), ('Básquet',  '🏀'), ('Cine',     '🎬'),
    ('Fiesta',   '🎉'), ('Café',     '☕'), ('Arte',     '🎨'),
    ('Running',  '🏃'), ('Yoga',     '🧘'), ('Ciclismo', '🚴'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPrefs();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(kUserId)
          .get();
      final data = doc.data() ?? {};
      _nameCtrl.text  = data['name']  as String? ?? '';
      _cityCtrl.text  = data['city']  as String? ?? '';
      _phoneCtrl.text = data['phone'] as String? ?? '';
      final raw = data['interests'] as List<dynamic>? ?? [];
      if (mounted) {
        setState(() {
          _selectedInterests = raw.cast<String>().toSet();
          _loadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notifications = p.getBool('notifications') ?? true;
        _language      = p.getString('language') ?? 'Español';
      });
    }
  }

  // ── Save actions ─────────────────────────────────────────────────────────────

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(kUserId)
          .set({
        'name': _nameCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
      }, SetOptions(merge: true));
      if (mounted) _snack('Perfil actualizado ✓');
    } catch (_) {}
    if (mounted) setState(() => _savingProfile = false);
  }

  Future<void> _saveInterests() async {
    setState(() => _savingInterests = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(kUserId)
          .set({'interests': _selectedInterests.toList()},
              SetOptions(merge: true));
      if (mounted) _snack('Intereses guardados ✓');
    } catch (_) {}
    if (mounted) setState(() => _savingInterests = false);
  }

  Future<void> _savePhone() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty &&
        !RegExp(r'^\+\d{8,15}$').hasMatch(phone)) {
      _snack('Formato inválido. Ej: +56912345678', isError: true);
      return;
    }
    setState(() => _savingPhone = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(kUserId)
          .set({'phone': phone}, SetOptions(merge: true));
      if (mounted) _snack('Teléfono guardado ✓');
    } catch (_) {}
    if (mounted) setState(() => _savingPhone = false);
  }

  Future<void> _setNotifications(bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('notifications', val);
    setState(() => _notifications = val);
  }

  Future<void> _setLanguage(String lang) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('language', lang);
    setState(() => _language = lang);
  }

  Future<void> _signOut() {
    return Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar cuenta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text(
          'Esta acción no se puede deshacer. Todos tus datos serán eliminados permanentemente.',
          style: TextStyle(color: Colors.white60, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(kUserId)
        .delete();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.white12,
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(title: const Text('Configuración')),
      body: _loadingUser
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _buildProfileSection(),
                _sectionGap(),
                _buildInterestsSection(),
                _sectionGap(),
                _buildPhoneSection(),
                _sectionGap(),
                _buildNotificationsSection(),
                _sectionGap(),
                _buildLanguageSection(),
                _sectionGap(),
                _buildAccountSection(),
              ],
            ),
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────────

  Widget _buildProfileSection() {
    final initial = _nameCtrl.text.trim().isEmpty
        ? 'U'
        : _nameCtrl.text.trim()[0].toUpperCase();

    return _Section(
      title: 'PERFIL',
      child: Column(children: [
        // Avatar
        GestureDetector(
          onTap: () => _snack('Próximamente: subir foto de perfil'),
          child: Stack(alignment: Alignment.bottomRight, children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: AppTheme.accent,
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_outlined,
                  color: Colors.white70, size: 16),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        DarkField(controller: _nameCtrl, hint: 'Nombre completo'),
        const SizedBox(height: 12),
        DarkField(controller: _cityCtrl, hint: 'Ciudad'),
        const SizedBox(height: 16),
        _saveButton(
          label: 'Guardar perfil',
          loading: _savingProfile,
          onPressed: _saveProfile,
        ),
      ]),
    );
  }

  Widget _buildInterestsSection() {
    return _Section(
      title: 'INTERESES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selecciona todo lo que te gusta hacer',
              style:
                  TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allInterests.map((pair) {
              final (label, emoji) = pair;
              final sel = _selectedInterests.contains(label);
              return GestureDetector(
                onTap: () => setState(() => sel
                    ? _selectedInterests.remove(label)
                    : _selectedInterests.add(label)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppTheme.accent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel
                          ? AppTheme.accent
                          : Colors.white.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(emoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(label,
                        style: TextStyle(
                            color: sel
                                ? Colors.white
                                : Colors.white60,
                            fontSize: 13,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.w500)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _saveButton(
            label: 'Guardar intereses',
            loading: _savingInterests,
            onPressed: _selectedInterests.isEmpty
                ? null
                : _saveInterests,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneSection() {
    return _Section(
      title: 'WHATSAPP',
      child: Column(children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tu número recibe notificaciones cuando un plan se confirma.',
            style:
                TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        const SizedBox(height: 14),
        DarkField(
          controller: _phoneCtrl,
          hint: '+56912345678',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        _saveButton(
          label: 'Guardar teléfono',
          loading: _savingPhone,
          onPressed: _savePhone,
        ),
      ]),
    );
  }

  Widget _buildNotificationsSection() {
    return _Section(
      title: 'NOTIFICACIONES',
      child: _ToggleRow(
        label: 'Activar notificaciones',
        subtitle: 'Recibe alertas de planes y quorum',
        value: _notifications,
        onChanged: _setNotifications,
      ),
    );
  }

  Widget _buildLanguageSection() {
    return _Section(
      title: 'IDIOMA',
      child: Column(
        children: ['Español', 'English'].map((lang) {
          final sel = _language == lang;
          return GestureDetector(
            onTap: () => _setLanguage(lang),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: sel
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel
                        ? AppTheme.accent.withValues(alpha: 0.5)
                        : Colors.transparent),
              ),
              child: Row(children: [
                Text(lang == 'Español' ? '🇪🇸' : '🇬🇧',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(lang,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.white60,
                          fontSize: 15,
                          fontWeight: sel
                              ? FontWeight.w700
                              : FontWeight.w500)),
                ),
                if (sel)
                  const Icon(Icons.check_circle,
                      color: AppTheme.accent, size: 20),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccountSection() {
    return _Section(
      title: 'CUENTA',
      child: Column(children: [
        _accountButton(
          icon: Icons.logout_rounded,
          label: 'Cerrar sesión',
          onTap: _signOut,
        ),
        const SizedBox(height: 10),
        _accountButton(
          icon: Icons.delete_outline_rounded,
          label: 'Eliminar cuenta',
          onTap: _deleteAccount,
          isDestructive: true,
        ),
      ]),
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────────

  Widget _saveButton({
    required String label,
    required bool loading,
    VoidCallback? onPressed,
  }) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppTheme.accent.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      );

  Widget _accountButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.accent : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.accent.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDestructive
                  ? AppTheme.accent.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.chevron_right, color: color.withValues(alpha: 0.4), size: 20),
        ]),
      ),
    );
  }

  Widget _sectionGap() => const SizedBox(height: 28);
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          child,
        ],
      );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.label,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.accent,
            trackColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppTheme.accent.withValues(alpha: 0.3)
                  : Colors.white12,
            ),
          ),
        ]),
      );
}
