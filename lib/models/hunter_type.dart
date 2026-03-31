import 'package:flutter/material.dart';

enum HunterType { stalker, rusher, trapper, berserk }

class HunterTypeData {
  final HunterType type;
  final String name;
  final String description;
  final String abilityName;
  final String abilityDescription;
  final Color color;
  final IconData icon;
  final double baseSpeed;
  final int baseDamage;
  final int abilityCooldownSec;

  const HunterTypeData({
    required this.type,
    required this.name,
    required this.description,
    required this.abilityName,
    required this.abilityDescription,
    required this.color,
    required this.icon,
    required this.baseSpeed,
    required this.baseDamage,
    required this.abilityCooldownSec,
  });

  static const Map<HunterType, HunterTypeData> all = {
    HunterType.stalker: HunterTypeData(
      type: HunterType.stalker,
      name: 'THE STALKER',
      description: 'Silent. Patient. Unseen.',
      abilityName: 'VANISH',
      abilityDescription: 'Turns invisible for 4 seconds',
      color: Color(0xFF9900CC),
      icon: Icons.visibility_off,
      baseSpeed: 4.0,
      baseDamage: 34,
      abilityCooldownSec: 12,
    ),
    HunterType.rusher: HunterTypeData(
      type: HunterType.rusher,
      name: 'THE RUSHER',
      description: 'Fast. Relentless. Unstoppable.',
      abilityName: 'SURGE',
      abilityDescription: 'Triple speed for 3 seconds',
      color: Color(0xFFFF6600),
      icon: Icons.bolt,
      baseSpeed: 5.0,
      baseDamage: 25,
      abilityCooldownSec: 10,
    ),
    HunterType.trapper: HunterTypeData(
      type: HunterType.trapper,
      name: 'THE TRAPPER',
      description: 'Cunning. Strategic. Deadly.',
      abilityName: 'TRAP',
      abilityDescription: 'Places a trap that slows survivors',
      color: Color(0xFF996600),
      icon: Icons.dangerous,
      baseSpeed: 3.5,
      baseDamage: 40,
      abilityCooldownSec: 8,
    ),
    HunterType.berserk: HunterTypeData(
      type: HunterType.berserk,
      name: 'THE BERSERK',
      description: 'Brutal. Overwhelming. Fatal.',
      abilityName: 'RAGE',
      abilityDescription: 'Next attack is instant kill',
      color: Color(0xFFCC0000),
      icon: Icons.local_fire_department,
      baseSpeed: 2.8,
      baseDamage: 100,
      abilityCooldownSec: 20,
    ),
  };
}
