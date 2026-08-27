import 'package:flutter/material.dart';

import '../services/digital_counter_service.dart';
import '../widgets/digital_counter_screen.dart';

class TasbeehScreen extends StatelessWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DigitalCounterScreen(
      title: 'المسبحة الإلكترونية',
      dhikrText: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
      service: DigitalCounterService('tasbeeh_counter_v1', defaultTarget: 33),
      targetPresets: const [33, 99, 100, 500, 1000],
    );
  }
}
