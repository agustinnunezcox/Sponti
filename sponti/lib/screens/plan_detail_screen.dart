import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan.dart';
import '../services/plan_service.dart';
import '../theme/app_theme.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;
  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  final _service = PlanService();
  bool _joining = false;
  bool _joined = false;

  static const _mockParticipants = [
    _Participant('Matías', 24, ['⚽', '🍺', '🎵']),
    _Participant('Camila', 22, ['🎭', '🌮', '🎨']),
    _Participant('Diego', 27, ['🏕️', '⚽', '🏄']),
    _Participant('Valentina', 25, ['🎵', '🧘', '🎬']),
    _Participant('Lucas', 23, ['🍺', '🎾', '🏃']),
  ];

  static const _avatarColors = [
    Color(0xFF1D9E75),
    Color(0xFF7B2FBE),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
    Color(0xFFFF6B35),
  ];

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await _service.joinPlan(widget.plan.id, 'user_test_01');
      if (!mounted) return;
      setState(() => _joined = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Te uniste a "${widget.plan.title}"! 🎉'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al unirse: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final count = plan.joinedCount.clamp(0, _mockParticipants.length);
    final participants = _mockParticipants.sublist(0, count);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(plan),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCards(plan),
                  const SizedBox(height: 20),
                  _buildWhatsAppBadge(),
                  if (plan.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDescription(plan),
                  ],
                  const SizedBox(height: 24),
                  _buildQuorumSection(plan),
                  if (participants.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildParticipants(participants),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildJoinButton(plan),
    );
  }

  SliverAppBar _buildHeader(Plan plan) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.dark,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppTheme.dark,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(plan.category.emoji,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Text(
                          plan.category.label,
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    plan.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${plan.place} · ${plan.city}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards(Plan plan) {
    return Row(
      children: [
        _InfoCard(
          icon: Icons.calendar_today_outlined,
          label: 'Fecha',
          value: DateFormat('d MMM').format(plan.time),
        ),
        const SizedBox(width: 10),
        _InfoCard(
          icon: Icons.access_time_rounded,
          label: 'Hora',
          value: DateFormat('h:mm a').format(plan.time),
        ),
        const SizedBox(width: 10),
        _InfoCard(
          icon: Icons.attach_money_rounded,
          label: 'Precio',
          value: '\$${plan.price.toStringAsFixed(0)} USD',
          highlight: true,
        ),
      ],
    );
  }

  Widget _buildWhatsAppBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF25D366).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grupo de WhatsApp automático',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.textPrimary)),
                SizedBox(height: 2),
                Text('Se crea cuando se confirma el quorum',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Auto',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(Plan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Descripción',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Text(plan.description,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
      ],
    );
  }

  Widget _buildQuorumSection(Plan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quorum',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        if (!plan.hasQuorum)
          Row(
            children: [
              const Icon(Icons.people_outline,
                  size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text('${plan.joinedCount} unidos · sin quorum',
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary)),
            ],
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.isConfirmed
                    ? '✅ Plan confirmado'
                    : 'Faltan ${plan.spotsToConfirm} personas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: plan.isConfirmed
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                ),
              ),
              Text('${plan.joinedCount} / ${plan.quorumMin}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: plan.quorumProgress,
              backgroundColor: AppTheme.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.isConfirmed
                ? 'Se te cobrará \$${plan.price.toStringAsFixed(0)} USD al confirmar.'
                : 'Solo se cobra cuando se alcanza el quorum.',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ],
    );
  }

  Widget _buildParticipants(List<_Participant> participants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Participantes (${participants.length})',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ...participants.asMap().entries.map((e) =>
            _buildParticipantRow(e.value, _avatarColors[e.key % _avatarColors.length])),
      ],
    );
  }

  Widget _buildParticipantRow(_Participant p, Color color) {
    return Container(
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
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: Text(p.name[0],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.name}, ${p.age}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(p.interests.join('  '),
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton(Plan plan) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_joining || _joined) ? null : _join,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _joined ? const Color(0xFF16A34A) : AppTheme.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _joined
                ? const Color(0xFF16A34A)
                : AppTheme.accent.withOpacity(0.6),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _joining
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Text(
                  _joined
                      ? '¡Te uniste! 🎉'
                      : 'Unirme al plan · \$${plan.price.toStringAsFixed(0)} USD',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

class _Participant {
  final String name;
  final int age;
  final List<String> interests;
  const _Participant(this.name, this.age, this.interests);
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: highlight ? AppTheme.accent : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon,
                color: highlight ? Colors.white : AppTheme.accent, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: highlight ? Colors.white : AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: highlight ? Colors.white70 : AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
