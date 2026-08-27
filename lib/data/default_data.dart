import '../models/section.dart';
import '../models/zekr.dart';

class DefaultData {
  static String _id(String prefix, int index) => '${prefix}_$index';

  static List<Zekr> _morningAzkar() => [
        Zekr(
          id: _id('morning', 0),
          title: 'آية الكرسي',
          text:
              'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
          repeat: 1,
        ),
        Zekr(
          id: _id('morning', 1),
          title: 'سورة الإخلاص',
          text: 'قُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ',
          repeat: 3,
        ),
        Zekr(
          id: _id('morning', 2),
          title: 'سورة الفلق',
          text: 'قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِنْ شَرِّ مَا خَلَقَ',
          repeat: 3,
        ),
        Zekr(
          id: _id('morning', 3),
          title: 'سورة الناس',
          text: 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ',
          repeat: 3,
        ),
        Zekr(
          id: _id('morning', 4),
          title: 'سبحان الله',
          text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
          repeat: 100,
        ),
      ];

  static List<Zekr> _eveningAzkar() => [
        Zekr(
          id: _id('evening', 0),
          title: 'آية الكرسي',
          text:
              'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
          repeat: 1,
        ),
        Zekr(
          id: _id('evening', 1),
          title: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ',
          text:
              'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
          repeat: 3,
        ),
        Zekr(
          id: _id('evening', 2),
          title: 'سورة الإخلاص',
          text: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
          repeat: 3,
        ),
        Zekr(
          id: _id('evening', 3),
          title: 'الحمد لله',
          text: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا',
          repeat: 1,
        ),
      ];

  static List<Zekr> _wakeupAzkar() => [
        Zekr(
          id: _id('wakeup', 0),
          title: 'الحمد لله الذي أحيانا',
          text:
              'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
          repeat: 1,
        ),
        Zekr(
          id: _id('wakeup', 1),
          title: 'لا إله إلا الله',
          text: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
          repeat: 1,
        ),
      ];

  static List<Zekr> _sleepAzkar() => [
        Zekr(
          id: _id('sleep', 0),
          title: 'باسمك ربي',
          text: 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي وَبِكَ أَرْفَعُهُ',
          repeat: 1,
        ),
        Zekr(
          id: _id('sleep', 1),
          title: 'سورة الإخلاص والمعوذتين',
          text: 'قُلْ هُوَ اللَّهُ أَحَدٌ — قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ — قُلْ أَعُوذُ بِرَبِّ النَّاسِ',
          repeat: 3,
        ),
        Zekr(
          id: _id('sleep', 2),
          title: 'اللهم أسلمت نفسي',
          text:
              'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ وَفَوَّضْتُ أَمْرِي إِلَيْكَ',
          repeat: 1,
        ),
      ];

  static List<Zekr> _afterPrayerAzkar() => [
        Zekr(
          id: _id('prayer', 0),
          title: 'أستغفر الله',
          text: 'أَسْتَغْفِرُ اللَّهَ (ثلاث مرات)',
          repeat: 3,
        ),
        Zekr(
          id: _id('prayer', 1),
          title: 'اللهم أنت السلام',
          text: 'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ',
          repeat: 1,
        ),
        Zekr(
          id: _id('prayer', 2),
          title: 'سبحان الله',
          text: 'سُبْحَانَ اللَّهِ',
          repeat: 33,
        ),
        Zekr(
          id: _id('prayer', 3),
          title: 'الحمد لله',
          text: 'الْحَمْدُ لِلَّهِ',
          repeat: 33,
        ),
        Zekr(
          id: _id('prayer', 4),
          title: 'الله أكبر',
          text: 'اللَّهُ أَكْبَرُ',
          repeat: 33,
        ),
      ];

  static List<Zekr> azkarForSectionId(String sectionId) {
    switch (sectionId) {
      case 'morning':
        return _morningAzkar();
      case 'evening':
        return _eveningAzkar();
      case 'wakeup':
        return _wakeupAzkar();
      case 'sleep':
        return _sleepAzkar();
      case 'after_prayer':
        return _afterPrayerAzkar();
      default:
        return [];
    }
  }

  static List<Section> initialSections() => [
        Section(
          id: 'morning',
          name: '☀️ أذكار الصباح',
          azkar: _morningAzkar(),
        ),
        Section(
          id: 'evening',
          name: '🌙 أذكار المساء',
          azkar: _eveningAzkar(),
        ),
        Section(
          id: 'wakeup',
          name: '💡 أذكار الاستيقاظ',
          azkar: _wakeupAzkar(),
        ),
        Section(
          id: 'sleep',
          name: '💤 أذكار النوم',
          azkar: _sleepAzkar(),
        ),
        Section(
          id: 'after_prayer',
          name: '📿 أذكار بعد الصلاة',
          azkar: _afterPrayerAzkar(),
        ),
      ];

  static Section? findDefaultByName(String name) {
    for (final section in initialSections()) {
      if (section.name == name) return section;
    }
    return null;
  }
}
