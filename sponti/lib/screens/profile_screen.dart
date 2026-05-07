import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../auth/auth_gate.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_field.dart';
import 'groups_screen.dart';
import 'rating_screen.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _interests = [
    '⚽ Fútbol', '🎵 Música', '🍺 Drinks', '🌮 Comer', '🏕️ Aventura',
  ];

  static const _recentPlans = [
    _RecentPlan('UC vs Cruceiro', 5, 'Football', '⚽'),
    _RecentPlan('Jazz en el Parque', 4, 'Música', '🎵'),
    _RecentPlan('Tacos Night', 5, 'Comer', '🌮'),
  ];

  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(kUserId)
          .get();
      if (mounted) {
        setState(() => _phone = doc.data()?['phone'] as String?);
      }
    } catch (_) {}
  }

  Future<void> _editPhone() async {
    final ctrl = TextEditingController(text: _phone ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.dark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PhoneEditSheet(
        controller: ctrl,
        onSave: (phone) async {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(kUserId)
              .set({'phone': phone}, SetOptions(merge: true));
          if (mounted) setState(() => _phone = phone);
        },
      ),
    );

    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStats(),
                  const SizedBox(height: 24),
                  _buildInterests(),
                  const SizedBox(height: 24),
                  _buildRecentPlans(),
                  const SizedBox(height: 24),
                  _buildMenu(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader() {
    final hasPhone = _phone != null && _phone!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: hasPhone ? 240 : 220,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.dark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppTheme.dark,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.accent,
                    child: const Text('A',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Agustín, 25',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Santiago, Chile',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _editPhone,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasPhone
                              ? Icons.phone_outlined
                              : Icons.add_circle_outline,
                          color: hasPhone
                              ? Colors.white54
                              : AppTheme.accent,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasPhone ? _phone! : AppStrings.current.addWhatsapp,
                          style: TextStyle(
                            color: hasPhone ? Colors.white60 : AppTheme.accent,
                            fontSize: 13,
                            fontWeight: hasPhone
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return const Row(
      children: [
        _StatCard('12', 'Planes'),
        SizedBox(width: 12),
        _StatCard('4.8 ⭐', 'Rating'),
        SizedBox(width: 12),
        _StatCard('3', 'Ciudades'),
      ],
    );
  }

  Widget _buildInterests() {
    final s = AppStrings.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s.myInterests,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            GestureDetector(
              onTap: () {},
              child: Text(s.editLabel,
                  style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interests
              .map((i) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Text(i,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRecentPlans() {
    final s = AppStrings.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.recentPlans,
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ..._recentPlans.map((p) => GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingScreen(
                      planTitle: p.title, planEmoji: p.emoji),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary)),
                          Text(p.category,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                          5,
                          (i) => Icon(
                                i < p.stars
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppTheme.accent,
                                size: 16,
                              )),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildMenu() {
    final s = AppStrings.current;
    return Column(
      children: [
        _menuItem(Icons.group_outlined, s.menuGroups, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const GroupsScreen()));
        }),
        _menuItem(Icons.settings_outlined, s.menuSettings, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }),
        _menuItem(
          Icons.logout_rounded,
          s.menuSignOut,
          () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          ),
          isRed: true,
        ),
      ],
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isRed = false,
  }) {
    final color = isRed ? AppTheme.accent : AppTheme.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
            Icon(Icons.chevron_right,
                color: isRed ? AppTheme.accent : AppTheme.textSecondary,
                size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet de edición de teléfono ────────────────────────────────────────

class _PhoneEditSheet extends StatefulWidget {
  final TextEditingController controller;
  final Future<void> Function(String phone) onSave;

  const _PhoneEditSheet({required this.controller, required this.onSave});

  @override
  State<_PhoneEditSheet> createState() => _PhoneEditSheetState();
}

class _PhoneEditSheetState extends State<_PhoneEditSheet> {
  bool _saving = false;

  Future<void> _save() async {
    final phone = widget.controller.text.trim();

    if (phone.isNotEmpty && !RegExp(r'^\+\d{8,15}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato inválido. Ej: +56912345678'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(phone);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('[ProfileScreen] Error guardando teléfono: $e');
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teléfono WhatsApp',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Formato internacional: +56912345678',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          DarkField(
            controller: widget.controller,
            hint: '+56912345678',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Guardar',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RecentPlan {
  final String title;
  final int stars;
  final String category;
  final String emoji;
  const _RecentPlan(this.title, this.stars, this.category, this.emoji);
}
