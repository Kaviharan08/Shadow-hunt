import 'package:flutter/material.dart';
import '../models/hunter_type.dart';

class HunterSelectScreen extends StatefulWidget {
  final bool isSolo;
  const HunterSelectScreen({super.key, required this.isSolo});
  @override
  State<HunterSelectScreen> createState() => _HunterSelectScreenState();
}

class _HunterSelectScreenState extends State<HunterSelectScreen> {
  HunterType _selected = HunterType.stalker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF000000), Color(0xFF050F05)]),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF446644))),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CHOOSE YOUR HUNTER', style: TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 3)),
                    Text('Each hunter has unique abilities',
                        style: TextStyle(color: Color(0xFF446644), fontSize: 11)),
                  ]),
                ]),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: HunterTypeData.all.values.map((data) {
                      bool sel = _selected == data.type;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = data.type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: sel
                                ? data.color.withValues(alpha: 0.2)
                                : const Color(0xFF0A0A0A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel ? data.color : const Color(0xFF1A2A1A),
                              width: sel ? 2 : 1,
                            ),
                            boxShadow: sel ? [BoxShadow(color: data.color.withValues(alpha: 0.3),
                                blurRadius: 16, spreadRadius: 2)] : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: data.color.withValues(alpha: 0.2),
                                    border: Border.all(color: data.color.withValues(alpha: 0.5)),
                                  ),
                                  child: Icon(data.icon, color: data.color, size: 22),
                                ),
                                const Spacer(),
                                if (sel)
                                  Icon(Icons.check_circle, color: data.color, size: 20),
                              ]),
                              const SizedBox(height: 10),
                              Text(data.name, style: TextStyle(color: data.color,
                                  fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(data.description, style: const TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: data.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: data.color.withValues(alpha: 0.3)),
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(data.abilityName, style: TextStyle(color: data.color,
                                      fontWeight: FontWeight.bold, fontSize: 10)),
                                  Text(data.abilityDescription, style: const TextStyle(
                                      color: Colors.white38, fontSize: 9)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected.name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HunterTypeData.all[_selected]!.color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(HunterTypeData.all[_selected]!.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text('PLAY AS ${HunterTypeData.all[_selected]!.name}',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 14)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
