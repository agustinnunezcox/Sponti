import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan.dart';
import '../theme/app_theme.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;

  const PlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopStrip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMeta(),
                  const SizedBox(height: 14),
                  _buildQuorumBar(),
                  const SizedBox(height: 14),
                  _buildJoinButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStrip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: AppTheme.dark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Text(plan.category.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              plan.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '\$${plan.price.toStringAsFixed(0)} USD',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeta() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _metaItem(Icons.location_on_outlined,
            '${plan.city} · ${plan.place}'),
        _metaItem(
            Icons.access_time_rounded, DateFormat('h:mm a').format(plan.time)),
      ],
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuorumBar() {
    if (!plan.hasQuorum) {
      return Row(
        children: [
          const Icon(Icons.people_outline,
              size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text('${plan.joinedCount} unidos',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              plan.isConfirmed
                  ? '✅ Confirmado'
                  : '${plan.spotsToConfirm} más para confirmar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: plan.isConfirmed
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD97706),
              ),
            ),
            Text(
              '${plan.joinedCount}/${plan.quorumMin}',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: plan.quorumProgress,
            backgroundColor: const Color(0xFFF1F1F1),
            valueColor: AlwaysStoppedAnimation<Color>(
              plan.isConfirmed
                  ? const Color(0xFF16A34A)
                  : AppTheme.accent,
            ),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.dark,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        'Join Plan · \$${plan.price.toStringAsFixed(0)} USD',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
