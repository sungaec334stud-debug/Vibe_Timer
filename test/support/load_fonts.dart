import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the app's bundled fonts into the test font collection.
///
/// Without this, `flutter_test` substitutes a fallback font in which every
/// glyph is a full-em box, so `'60-Min Vibe Lab Roadmap'` measures ~365px
/// instead of ~187px and real, correct layouts report bogus RenderFlex
/// overflows. Loading the actual TTFs makes widget tests measure the same
/// widths the device does.
///
/// Call once from `setUpAll`.
Future<void> loadAppFonts() async {
  const Map<String, List<String>> families = <String, List<String>>{
    'Outfit': <String>[
      'assets/fonts/Outfit-500.ttf',
      'assets/fonts/Outfit-600.ttf',
      'assets/fonts/Outfit-700.ttf',
      'assets/fonts/Outfit-800.ttf',
    ],
    'PlusJakartaSans': <String>[
      'assets/fonts/PlusJakartaSans-400.ttf',
      'assets/fonts/PlusJakartaSans-500.ttf',
      'assets/fonts/PlusJakartaSans-600.ttf',
      'assets/fonts/PlusJakartaSans-700.ttf',
    ],
    'JetBrainsMono': <String>[
      'assets/fonts/JetBrainsMono-500.ttf',
      'assets/fonts/JetBrainsMono-700.ttf',
    ],
  };

  for (final MapEntry<String, List<String>> family in families.entries) {
    final FontLoader loader = FontLoader(family.key);
    for (final String path in family.value) {
      loader.addFont(rootBundle.load(path));
    }
    await loader.load();
  }
}
