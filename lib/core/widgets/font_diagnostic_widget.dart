import 'package:flutter/material.dart';

/// Diagnostic widget to test Arabic font rendering, specifically for U+0671 (ARABIC LETTER ALEF WASLA)
/// 
/// Usage: Add this widget to a screen to verify font rendering:
/// ```dart
/// FontDiagnosticWidget()
/// ```
/// 
/// This widget displays:
/// - Test strings with and without Alef Wasla (ٱ)
/// - Code point information
/// - Font family verification
/// - TextPainter debug info
class FontDiagnosticWidget extends StatefulWidget {
  const FontDiagnosticWidget({super.key});

  @override
  State<FontDiagnosticWidget> createState() => _FontDiagnosticWidgetState();
}

class _FontDiagnosticWidgetState extends State<FontDiagnosticWidget> {
  String? _fontInfo;
  String? _painterInfo;

  @override
  void initState() {
    super.initState();
    _analyzeFont();
  }

  Future<void> _analyzeFont() async {
    // Test strings
    const testWithWasla = 'ٱلْحَمْدُ'; // Contains U+0671 (Alef Wasla)
    const testWithAlif = 'اَلْحَمْدُ'; // Contains U+0627 (regular alif)
    
    // Analyze code points
    final waslaCodePoints = testWithWasla.runes.map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}').join(' ');
    final alifCodePoints = testWithAlif.runes.map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}').join(' ');
    
    // Use TextPainter to verify font rendering
    final textPainter = TextPainter(
      text: const TextSpan(
        text: testWithWasla,
        style: TextStyle(
          fontFamily: 'KFGQPCUthmanic',
          fontFamilyFallback: ['UthmanicHafsV22', 'UthmanicHafs', 'ScheherazadeNew'],
          fontSize: 24,
          locale: Locale('ar'),
        ),
      ),
      textDirection: TextDirection.rtl,
      locale: const Locale('ar'),
    );
    
    textPainter.layout();
    
    setState(() {
      _fontInfo = '''
Test String 1 (with Wasla): $testWithWasla
Code Points: $waslaCodePoints
Expected: U+0671 (ARABIC LETTER ALEF WASLA)

Test String 2 (with Alif): $testWithAlif
Code Points: $alifCodePoints
Expected: U+0627 (ARABIC LETTER ALEF)

Font Family: KFGQPCUthmanic
Fallback: UthmanicHafsV22, UthmanicHafs, ScheherazadeNew
''';
      
      _painterInfo = '''
TextPainter Layout:
- Width: ${textPainter.width}
- Height: ${textPainter.height}
- Did Exceed Max Lines: ${textPainter.didExceedMaxLines}
''';
    });
  }

  @override
  Widget build(BuildContext context) {
    const testWithWasla = 'ٱلْحَمْدُ';
    const testWithAlif = 'اَلْحَمْدُ';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arabic Font Diagnostic'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Font Rendering Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Test with Wasla
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test 1: With Alef Wasla (ٱ)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Localizations.override(
                      context: context,
                      locale: const Locale('ar'),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: SelectableText.rich(
                          const TextSpan(
                            text: testWithWasla,
                            style: TextStyle(
                              fontFamily: 'KFGQPCUthmanic',
                              fontFamilyFallback: ['UthmanicHafsV22', 'UthmanicHafs', 'ScheherazadeNew'],
                              fontSize: 32,
                              locale: Locale('ar'),
                            ),
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Code Points: ${testWithWasla.runes.map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}').join(' ')}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    const Text(
                      'Expected: U+0671 (ARABIC LETTER ALEF WASLA) should render correctly',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test with regular Alif
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test 2: With Regular Alif (ا)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Localizations.override(
                      context: context,
                      locale: const Locale('ar'),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: SelectableText.rich(
                          const TextSpan(
                            text: testWithAlif,
                            style: TextStyle(
                              fontFamily: 'KFGQPCUthmanic',
                              fontFamilyFallback: ['UthmanicHafsV22', 'UthmanicHafs', 'ScheherazadeNew'],
                              fontSize: 32,
                              locale: Locale('ar'),
                            ),
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Code Points: ${testWithAlif.runes.map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}').join(' ')}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    const Text(
                      'Expected: U+0627 (ARABIC LETTER ALEF) should render correctly',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Debug Info
            if (_fontInfo != null) ...[
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Debug Information',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fontInfo!,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      if (_painterInfo != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _painterInfo!,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Instructions
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Verify:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Check if Test 1 shows a black circle/tofu instead of Alef Wasla'),
                    Text('2. If black circle appears, the font may not support U+0671'),
                    Text('3. Compare with Test 2 (regular alif) - it should render correctly'),
                    Text('4. If both render correctly, font is working properly'),
                    Text('5. If only Test 2 works, enable replaceWaslaWithAlif fallback'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
