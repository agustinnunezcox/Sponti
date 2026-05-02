import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/plan.dart';
import '../theme/app_theme.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onJoin;

  const PlanCard({super.key, required this.plan, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryTag(),
            const SizedBox(height: 10),
            _buildTitle(),
            const SizedBox(height: 8),
            _buildMeta(),
            const SizedBox(height: 16),
            _buildQuorumBar(),
            const SizedBox(height: 16),
            _buildJoinButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: plan.category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(plan.category.emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            plan.category.label,
            style: TextStyle(
              color: plan.category.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      plan.title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        height: 1.2,
      ),
    );
  }

  Widget _buildMeta() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _metaItem(Icons.location_on_outlined, '${plan.city} · ${plan.place}'),
        _metaItem(Icons.access_time_rounded, DateFormat('h:mm a').format(plan.time)),
      ],
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuorumBar() {
    final confirmed = plan.isConfirmed;
    final barColor = confirmed ? AppTheme.primary : const Color(0xFFF59E0B);
    final bgColor = confirmed ? AppTheme.primaryLight : const Color(0xFFFEF3C7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                confirmed
                    ? '✅  Plan confirmed!'
                    : '${plan.spotsToConfirm} more to confirm',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: confirmed ? AppTheme.primary : const Color(0xFFD97706),
                ),
              ),
            ),
            Text(
              '${plan.joinedCount} / ${plan.quorumMin} joined',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: plan.quorumProgress,
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        child: const Text(
          'Join Plan · \$2 USD',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
