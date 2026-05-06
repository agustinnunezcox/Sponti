import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'rating_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _interests = [
    '⚽ Fútbol',
    '🎵 Música',
    '🍺 Drinks',
    '🌮 Comer',
    '🏕️ Aventura',
  ];

  static const _recentPlans = [
    _RecentPlan('UC vs Cruceiro', 5, 'Football', '⚽'),
    _RecentPlan('Jazz en el Parque', 4, 'Música', '🎵'),
    _RecentPlan('Tacos Night', 5, 'Comer', '🌮'),
  ];

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
                  _buildInterests(context),
                  const SizedBox(height: 24),
                  _buildRecentPlans(context),
                  const SizedBox(height: 24),
                  _buildMenu(context),
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
    return SliverAppBar(
      expandedHeight: 210,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: const [
        _StatCard('12', 'Planes'),
        SizedBox(width: 12),
        _StatCard('4.8 ⭐', 'Rating'),
        SizedBox(width: 12),
        _StatCard('3', 'Ciudades'),
      ],
    );
  }

  Widget _buildInterests(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mis intereses',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            GestureDetector(
              onTap: () {},
              child: const Text('Editar',
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

  Widget _buildRecentPlans(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Planes recientes',
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
                        color: Colors.black.withOpacity(0.04),
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

  Widget _buildMenu(BuildContext context) {
    return Column(
      children: [
        _menuItem(context, Icons.group_outlined, 'Mis grupos', () {}),
        _menuItem(context, Icons.settings_outlined, 'Configuración', () {}),
        _menuItem(
          context,
          Icons.logout_rounded,
          'Cerrar sesión',
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
    BuildContext context,
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
                color: Colors.black.withOpacity(0.04),
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
                color: Colors.black.withOpacity(0.04),
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
