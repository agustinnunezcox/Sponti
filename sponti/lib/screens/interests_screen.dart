import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../auth/auth_gate.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};
  String _search = '';
  bool _expanded = false;
  bool _saving = false;
  final List<_Interest> _custom = [];

  static const _base = [
    _Interest('Fútbol', '⚽'),
    _Interest('Música', '🎵'),
    _Interest('Drinks', '🍺'),
    _Interest('Surf', '🏄'),
    _Interest('Comer', '🌮'),
    _Interest('Tenis', '🎾'),
    _Interest('Teatro', '🎭'),
    _Interest('Aventura', '🏕️'),
  ];

  static const _extra = [
    _Interest('Padel', '🏓'),
    _Interest('Golf', '⛳'),
    _Interest('Básquet', '🏀'),
    _Interest('Cine', '🎬'),
    _Interest('Fiesta', '🎉'),
    _Interest('Café', '☕'),
    _Interest('Arte', '🎨'),
    _Interest('Running', '🏃'),
    _Interest('Yoga', '🧘'),
    _Interest('Ciclismo', '🚴'),
  ];

  List<_Interest> get _allPredefined => [..._base, ..._extra];

  // Items shown in the grid depending on search / expanded state.
  List<_Interest> get _visibleItems {
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      return [..._allPredefined, ..._custom]
          .where((i) => i.label.toLowerCase().contains(q))
          .toList();
    }
    // Custom interests always visible (user added them intentionally).
    if (_expanded) return [..._base, ..._extra, ..._custom];
    return [..._base, ..._custom];
  }

  // True when the search text has no match in any known interest.
  bool get _hasNoMatch {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return false;
    return ![..._allPredefined, ..._custom]
        .any((i) => i.label.toLowerCase().contains(q));
  }

  String get _capitalizedSearch {
    final s = _search.trim();
    if (s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1);
  }

  void _addCustom() {
    final label = _capitalizedSearch;
    if (label.isEmpty) return;
    setState(() {
      if (!_custom.any((c) => c.label.toLowerCase() == label.toLowerCase())) {
        _custom.add(_Interest(label, '✨'));
      }
      _selected.add(label);
      _searchCtrl.clear();
      _search = '';
      _expanded = true;
    });
  }

  void _toggleItem(String label) {
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    final list = _selected.toList();
    print('[InterestsScreen] Guardando intereses para $kUserId: $list');
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(kUserId)
          .set({'interests': list}, SetOptions(merge: true));
      print('[InterestsScreen] Guardado OK');
    } catch (e) {
      print('[InterestsScreen] ERROR al guardar: $e');
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    final isSearching = _search.isNotEmpty;
    final showToggle = !isSearching;
    final itemCount = items.length + (showToggle ? 1 : 0);

    return Scaffold(
      backgroundColor: AppTheme.dark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (showToggle && i == items.length) {
                      return _buildToggleCell();
                    }
                    return _buildInterestCell(items[i]);
                  },
                  childCount: itemCount,
                ),
              ),
            ),
            if (_hasNoMatch) SliverToBoxAdapter(child: _buildAddChip()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: AppTheme.dark,
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
        child: ElevatedButton(
          onPressed: (_saving || _selected.isEmpty) ? null : _continue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.accent.withOpacity(0.35),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Text('Ver mis planes →',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Qué harías hoy\nsi pudieras?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar o agregar interés...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white38, size: 20),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestCell(_Interest item) {
    final selected = _selected.contains(item.label);
    return GestureDetector(
      onTap: () => _toggleItem(item.label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleCell() {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white60,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              _expanded ? 'Ver menos' : 'Ver más',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddChip() {
    final label = _capitalizedSearch;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: GestureDetector(
        onTap: _addCustom,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppTheme.accent.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle_outline,
                  color: AppTheme.accent, size: 20),
              const SizedBox(width: 10),
              Text(
                '+ Agregar "$label"',
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Interest {
  final String label;
  final String emoji;
  const _Interest(this.label, this.emoji);
}
