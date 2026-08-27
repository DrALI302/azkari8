import 'package:flutter/material.dart';

import '../services/digital_counter_service.dart';
import '../widgets/digital_counter_screen.dart';

class SalawatScreen extends StatelessWidget {
  const SalawatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DigitalCounterScreen(
      title: 'عداد الصلاة على النبي',
      dhikrText: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
      service: DigitalCounterService('salawat_counter_v1', defaultTarget: 100),
      targetPresets: const [10, 33, 100, 500, 1000],
      accentColor: Colors.teal,
    );
  }
}
