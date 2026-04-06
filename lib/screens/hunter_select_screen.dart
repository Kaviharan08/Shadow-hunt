import 'package:flutter/material.dart';
import '../models/hunter_type.dart';
import '../widgets/horror_bg.dart';
import '../widgets/forest_map.dart';

class HunterSelectScreen extends StatefulWidget {
  final bool isSolo;
  const HunterSelectScreen({super.key, required this.isSolo});
  @override
  State<HunterSelectScreen> createState() => _HunterSelectScreenState();
}

class _HunterSelectScreenState extends State<HunterSelectScreen>
    with SingleTickerProviderStateMixin {
  HunterType _selected = HunterType.stalker;
  late AnimationController _introCtrl;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedData = HunterTypeData.all[_selected]!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: HorrorBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHOOSE YOUR HUNTER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.8,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Each hunter has a different power and pressure style',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _selectedHunterBanner(selectedData),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.93,
                      children: HunterTypeData.all.values.map((data) {
                        final sel = _selected == data.type;
                        return _hunterCard(data, sel);
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE11B83), Color(0xFF29D8FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selectedData.color.withOpacity(0.26),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, _selected.name),
                      icon: const Icon(Icons.sensors_rounded, color: Colors.white),
                      label: Text(
                        'PLAY AS ${selectedData.name.replaceAll('THE ', '')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedHunterBanner(HunterTypeData selectedData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              selectedData.color.withOpacity(0.22),
              ToxicTheme.cyan.withOpacity(0.16),
              const Color(0xFF0B1020).withOpacity(0.82),
            ],
          ),
          boxShadow: [
            BoxShadow(color: selectedData.color.withOpacity(0.22), blurRadius: 28),
          ],
        ),
        child: Row(
          children: [
            HunterPortrait(hunterType: _selected.name, size: 120, isSelected: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SELECTED HUNTER',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedData.name.replaceAll('THE ', ''),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      shadows: [Shadow(color: selectedData.color, blurRadius: 14)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedData.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statChip(Icons.auto_awesome, selectedData.abilityName, selectedData.color),
                      _statChip(Icons.flash_on, 'SPD ${selectedData.baseSpeed.toStringAsFixed(1)}', ToxicTheme.cyan),
                      _statChip(Icons.gps_fixed, 'DMG ${selectedData.baseDamage}', ToxicTheme.red),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hunterCard(HunterTypeData data, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _selected = data.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? data.color : Colors.white.withOpacity(0.08),
            width: selected ? 2 : 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: selected
                ? [
                    data.color.withOpacity(0.20),
                    ToxicTheme.cyan.withOpacity(0.14),
                    const Color(0xFF09101C),
                  ]
                : [
                    const Color(0xFF0C1322).withOpacity(0.92),
                    const Color(0xFF0A0F1B).withOpacity(0.92),
                  ],
          ),
          boxShadow: selected
              ? [BoxShadow(color: data.color.withOpacity(0.26), blurRadius: 24)]
              : [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 14)],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -10,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [data.color.withOpacity(0.18), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (selected)
                        Icon(Icons.check_circle_rounded, color: data.color, size: 20)
                      else
                        const Icon(Icons.radio_button_unchecked, color: Colors.white24, size: 18),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: data.color.withOpacity(0.14),
                          border: Border.all(color: data.color.withOpacity(0.28)),
                        ),
                        child: Icon(data.icon, color: data.color, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: HunterPortrait(hunterType: data.type.name, size: 130, isSelected: selected),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.name.replaceAll('THE ', ''),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.description,
                    style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [data.color.withOpacity(0.22), Colors.white.withOpacity(0.06)],
                      ),
                      border: Border.all(color: data.color.withOpacity(0.22)),
                    ),
                    child: Row(
                      children: [
                        Icon(data.icon, color: data.color, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data.abilityName,
                            style: TextStyle(
                              color: data.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.14),
        border: Border.all(color: color.withOpacity(0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
