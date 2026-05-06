import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../services/plan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/plan_card.dart';
import '../widgets/sponti_logo.dart';
import 'plan_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = PlanService();
  String _selectedCity = 'All';
  List<String> _cities = ['All'];
  late Stream<List<Plan>> _plansStream;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _plansStream = _service.getTodayPlans(city: _selectedCity);
  }

  void _updateCities(List<Plan> plans) {
    final newCities = [
      'All',
      ...plans.map((p) => p.city).toSet().toList()..sort()
    ];
    if (newCities.join() != _cities.join()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _cities = newCities);
      });
    }
  }

  void _setCity(String city) {
    setState(() {
      _selectedCity = city;
      _plansStream = _service.getTodayPlans(city: city);
    });
  }

  void _openDetail(Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: plan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _navIndex == 0
          ? Column(children: [_buildHeader(), Expanded(child: _buildPlanList())])
          : _navIndex == 1
              ? _buildMapTab()
              : const ProfileScreen(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.dark,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(
                children: [
                  const SpontiLogo(fontSize: 22),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 22),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 18),
                  GestureDetector(
                    onTap: () => setState(() => _navIndex = 2),
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white12,
                      child: Icon(Icons.person_outline,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _cities.length,
                itemBuilder: (_, i) {
                  final city = _cities[i];
                  final selected = _selectedCity == city;
                  return GestureDetector(
                    onTap: () => _setCity(city),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8, bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accent
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        city,
                        style: TextStyle(
                          color:
                              selected ? Colors.white : Colors.white60,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanList() {
    return StreamBuilder<List<Plan>>(
      stream: _plansStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent));
        }
        final plans = snapshot.data ?? [];
        _updateCities(plans);
        if (plans.isEmpty) return _buildEmpty();
        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 32),
          itemCount: plans.length,
          itemBuilder: (_, i) => PlanCard(
            plan: plans[i],
            onTap: () => _openDetail(plans[i]),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🌍', style: TextStyle(fontSize: 52)),
          SizedBox(height: 16),
          Text('No hay planes por aquí',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          SizedBox(height: 6),
          Text('¡Sé el primero en crear uno!',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 60, color: AppTheme.textSecondary),
            SizedBox(height: 16),
            Text('Mapa próximamente',
                style:
                    TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _navIndex,
      onTap: (i) => setState(() => _navIndex = i),
      backgroundColor: Colors.white,
      selectedItemColor: AppTheme.accent,
      unselectedItemColor: AppTheme.textSecondary,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.flash_on_rounded), label: 'Plans'),
        BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined), label: 'Map'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
