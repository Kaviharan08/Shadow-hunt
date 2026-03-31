import 'dart:ui';

enum PowerupType { speedBoost, invisibility, healthPack, flashbang }

class Powerup {
  final String id;
  final PowerupType type;
  final Offset position;
  bool isCollected;

  Powerup({
    required this.id,
    required this.type,
    required this.position,
    this.isCollected = false,
  });

  String get name {
    switch (type) {
      case PowerupType.speedBoost: return 'SPEED BOOST';
      case PowerupType.invisibility: return 'INVISIBILITY';
      case PowerupType.healthPack: return 'HEALTH PACK';
      case PowerupType.flashbang: return 'FLASHBANG';
    }
  }

  String get emoji {
    switch (type) {
      case PowerupType.speedBoost: return '⚡';
      case PowerupType.invisibility: return '👻';
      case PowerupType.healthPack: return '❤️';
      case PowerupType.flashbang: return '💥';
    }
  }

  static List<Powerup> generateForMap() => [
    Powerup(id: 'p1', type: PowerupType.speedBoost,   position: const Offset(420, 320)),
    Powerup(id: 'p2', type: PowerupType.healthPack,   position: const Offset(820, 480)),
    Powerup(id: 'p3', type: PowerupType.invisibility, position: const Offset(280, 720)),
    Powerup(id: 'p4', type: PowerupType.flashbang,    position: const Offset(1100, 360)),
    Powerup(id: 'p5', type: PowerupType.speedBoost,   position: const Offset(680, 900)),
    Powerup(id: 'p6', type: PowerupType.healthPack,   position: const Offset(1300, 700)),
    Powerup(id: 'p7', type: PowerupType.flashbang,    position: const Offset(500, 1100)),
    Powerup(id: 'p8', type: PowerupType.invisibility, position: const Offset(980, 1200)),
  ];
}

class Trap {
  final String id;
  final Offset position;
  bool isTriggered;

  Trap({required this.id, required this.position, this.isTriggered = false});
}

class ActiveEffect {
  final PowerupType type;
  final DateTime expiresAt;
  ActiveEffect({required this.type, required this.expiresAt});
  bool get isActive => DateTime.now().isBefore(expiresAt);
}
