import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../auth/auth_gate.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Create group sheet ───────────────────────────────────────────────────────

  Future<void> _showCreateGroup() async {
    final nameCtrl = TextEditingController();
    String selectedEmoji = '🎉';
    const emojis = ['🎉', '⚽', '🎵', '🍺', '🌮', '🏕️', '🎭', '🏄', '🎬', '☕'];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nuevo grupo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              // Emoji selector
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: emojis.length,
                  separatorBuilder: (ctx2, i2) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final e = emojis[i];
                    final sel = e == selectedEmoji;
                    return GestureDetector(
                      onTap: () => set(() => selectedEmoji = e),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.accent.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel ? AppTheme.accent : Colors.transparent,
                              width: 2),
                        ),
                        child: Center(
                            child: Text(e,
                                style: const TextStyle(fontSize: 22))),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style:
                    const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Nombre del grupo',
                  hintStyle:
                      const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .add({
                      'name': name,
                      'emoji': selectedEmoji,
                      'members': [kUserId],
                      'createdBy': kUserId,
                      'createdAt': Timestamp.now(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Crear grupo',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    nameCtrl.dispose();
  }

  // ── Group detail sheet ───────────────────────────────────────────────────────

  void _showGroupDetail(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final name = data['name'] as String? ?? 'Grupo';
    final emoji = data['emoji'] as String? ?? '🎉';
    final members = List<String>.from(data['members'] as List? ?? []);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              _GroupAvatar(emoji: emoji, size: 48),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text(
                    '${members.length} integrante${members.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ]),
            ]),
            const SizedBox(height: 20),
            const Text('INTEGRANTES',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            ...members.map((uid) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          AppTheme.accent.withValues(alpha: 0.2),
                      child: Text(
                          uid == kUserId
                              ? 'T'
                              : uid[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Text(uid == kUserId ? 'Tú' : uid,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ]),
                )),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Próximamente: invitar amigos')),
                    );
                  },
                  icon: const Icon(Icons.person_add_outlined,
                      size: 18),
                  label: const Text('Invitar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                        vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Ver planes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dark,
      appBar: AppBar(
        title: const Text('Mis Grupos'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: 'Grupos'),
            Tab(text: 'Mis Planes'),
          ],
        ),
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton(
              onPressed: _showCreateGroup,
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      body: TabBarView(
        controller: _tab,
        children: [_buildGroupsTab(), _buildPlansTab()],
      ),
    );
  }

  // ── Grupos tab ───────────────────────────────────────────────────────────────

  Widget _buildGroupsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: kUserId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.accent));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState('👥', 'Sin grupos aún',
              'Crea tu primer grupo de amigos\ncon el botón +');
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: docs.length,
          itemBuilder: (_, i) => _buildGroupCard(docs[i]),
        );
      },
    );
  }

  Widget _buildGroupCard(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final name = data['name'] as String? ?? 'Grupo';
    final emoji = data['emoji'] as String? ?? '🎉';
    final members =
        List<String>.from(data['members'] as List? ?? []);

    return GestureDetector(
      onTap: () => _showGroupDetail(doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          _GroupAvatar(emoji: emoji, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                    '${members.length} integrante${members.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          // Stacked member avatars (max 3)
          _MemberStack(members: members.take(3).toList()),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right,
              color: Colors.white38, size: 20),
        ]),
      ),
    );
  }

  // ── Mis Planes tab ───────────────────────────────────────────────────────────

  Widget _buildPlansTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('Plans')
          .where('joinedUsers', arrayContains: kUserId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppTheme.accent));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState('📋', 'Sin planes aún',
              'Únete a planes desde\nla pantalla principal');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) => _buildPlanCard(docs[i]),
        );
      },
    );
  }

  Widget _buildPlanCard(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final title = data['title'] as String? ?? 'Plan';
    final city = data['city'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final joined = (data['joinedCount'] as num?)?.toInt() ?? 0;
    final minPeople = (data['minPeople'] as num?)?.toInt() ?? 3;
    final category = data['category'] as String? ?? 'outdoor';
    final planId = doc.id;

    DateTime? time;
    final ts = data['time'];
    if (ts is Timestamp) time = ts.toDate();

    final isConfirmed = status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_categoryEmoji(category),
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                      '$city${time != null ? '  ·  ${_fmtDate(time)}' : ''}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            _StatusBadge(status: status),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (joined / minPeople).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                  isConfirmed ? Colors.greenAccent : AppTheme.accent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$joined / $minPeople personas',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
              if (isConfirmed)
                GestureDetector(
                  onTap: () => _shareWhatsApp(title, planId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Color(0xFF25D366), size: 13),
                        SizedBox(width: 4),
                        Text('WhatsApp',
                            style: TextStyle(
                                color: Color(0xFF25D366),
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareWhatsApp(String title, String planId) async {
    final text = Uri.encodeComponent(
        '¡El plan "$title" está confirmado! 🎉 Únete: https://sponti.app/plan/$planId');
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _categoryEmoji(String cat) => const {
        'football': '⚽',
        'sports': '🏆',
        'outdoor': '🌿',
        'food': '🌮',
        'culture': '🎭',
        'music': '🎵',
        'drinks': '🍺',
      }[cat.toLowerCase()] ??
      '✨';

  String _fmtDate(DateTime d) {
    const m = ['ene','feb','mar','abr','may','jun',
                'jul','ago','sep','oct','nov','dic'];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${m[d.month - 1]}  $hh:$mm';
  }

  Widget _emptyState(String emoji, String title, String sub) =>
      Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  height: 1.5)),
        ]),
      );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _GroupAvatar extends StatelessWidget {
  final String emoji;
  final double size;
  const _GroupAvatar({required this.emoji, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Center(
            child: Text(emoji,
                style: TextStyle(fontSize: size * 0.5))),
      );
}

class _MemberStack extends StatelessWidget {
  final List<String> members;
  const _MemberStack({required this.members});

  @override
  Widget build(BuildContext context) {
    const r = 14.0;
    final w = members.isEmpty ? 0.0 : r * 2 + (members.length - 1) * r;
    return SizedBox(
      width: w,
      height: r * 2,
      child: Stack(
        children: members.asMap().entries.map((e) => Positioned(
              left: e.key * r,
              child: CircleAvatar(
                radius: r,
                backgroundColor: AppTheme.accent,
                child: Text(
                  e.value == kUserId
                      ? 'T'
                      : e.value[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            )).toList(),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'confirmed' => ('Confirmado', Colors.greenAccent),
      'capturing' => ('Confirmando…', Colors.amberAccent),
      _ => ('Esperando quorum', Colors.orangeAccent),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}
