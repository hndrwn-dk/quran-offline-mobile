import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_offline/core/providers/settings_provider.dart';
import 'package:quran_offline/core/utils/mushaf_layout.dart';
import 'package:quran_offline/features/read/widgets/mushaf_text_settings_dialog.dart';

class MushafPageView extends ConsumerStatefulWidget {
  final int initialPage;

  const MushafPageView({super.key, required this.initialPage});

  @override
  ConsumerState<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends ConsumerState<MushafPageView> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    // For RTL swipe: page 1 = index 603 (last), page 604 = index 0 (first)
    // So initialPage 1 should be at index 603, initialPage 604 at index 0
    final initialIndex = 604 - widget.initialPage;
    _controller = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch settings to react to font size changes
    ref.watch(settingsProvider.select((s) => s.mushafFontSize));
    
    return PageView.builder(
      controller: _controller,
      reverse: true, // RTL swipe: swipe left = next page, swipe right = prev page
      itemCount: 604,
      itemBuilder: (context, index) {
        // Convert index to page number: index 0 = page 604, index 603 = page 1
        final pageNo = 604 - index;
        return MushafPage(
          pageNo: pageNo,
          onComputed: () {
            if (pageNo > 1) {
              // prewarm previous page (since reverse: true, index decreases)
              MushafLayoutCache.prewarm(context, pageNo - 1);
            }
          },
        );
      },
    );
  }
}

class MushafPage extends ConsumerStatefulWidget {
  final int pageNo;
  final VoidCallback? onComputed;

  const MushafPage({super.key, required this.pageNo, this.onComputed});

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  late Future<List<MushafLine>> _linesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshLines();
  }

  void _refreshLines() {
    _linesFuture = MushafLayoutCache.getPageLines(context, widget.pageNo);
  }

  @override
  void didUpdateWidget(MushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNo != widget.pageNo) {
      _refreshLines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final fontSize = settings.mushafFontSize;
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.onSurface.withOpacity(0.08),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.18),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.menu_book_outlined,
                size: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Qur'an",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Read and reflect',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Text settings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const MushafTextSettingsDialog(),
              ).then((_) {
                // Refresh lines when dialog closes (font size may have changed)
                setState(() {
                  _refreshLines();
                });
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MushafLine>>(
        future: _linesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final lines = snapshot.data ?? [];
          widget.onComputed?.call();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: lines
                              .map(
                                (line) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: RichText(
                                    textAlign: TextAlign.center, // Flutter doesn't support Arabic justify
                                    textDirection: TextDirection.rtl,
                                    text: TextSpan(
                                      children: line.toSpans(context, fontSize),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                      ),
                    ),
                  ),
                ),
                Text(
                  '${widget.pageNo}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

