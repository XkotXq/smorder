import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/session/recent_lines_providers.dart';
import '../../i18n/gen/strings.g.dart';
import '../../widgets/chip_grid.dart';
import '../../widgets/option_chip.dart';
import 'line_codes.dart';

/// The destination line, as the **first and largest thing on the form**.
///
/// Every order type but goods_transport is a line and nothing else, and the
/// line decides where a forklift drives - so it gets the weight of a
/// headline rather than looking like one more 40px dropdown among five
/// (which is what it used to be). The recently used lines sit next to it as
/// one-tap chips, because a foreman orders for their own line over and over
/// (see RecentLinesNotifier).
///
/// Picking from the full list opens a bottom sheet, the same shape as the
/// order-type picker on the list screen - on a phone a sheet of big rows
/// beats a dropdown. Every "tap one of these" on this form is the same
/// 48dp OptionChip (see widgets/option_chip.dart), recent lines included.
class LineHeroField extends ConsumerWidget {
  const LineHeroField({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showShadSheet<String>(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (_) => _LineSheet(label: label, selected: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.newOrder;
    final recent = (ref.watch(recentLinesProvider).value ?? const <String>[]).where((l) => l != value).toList();
    final chosen = value.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.muted),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _pick(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: chosen ? theme.colorScheme.accent : theme.colorScheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: chosen ? theme.colorScheme.primary : theme.colorScheme.border,
                    width: chosen ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      chosen ? value : t.linePick,
                      style: theme.textTheme.h3.copyWith(
                        fontSize: chosen ? 26 : 18,
                        fontWeight: FontWeight.w700,
                        color: chosen ? theme.colorScheme.primary : theme.colorScheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.chevronDown, size: 18, color: theme.colorScheme.mutedForeground),
                  ],
                ),
              ),
            ),
            if (recent.isNotEmpty) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final line in recent) OptionChip(label: line, onTap: () => onChanged(line))],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The full list of production lines, grouped the way the plant is laid out
/// (SH / ST / FC / FL) so a code is found by where it is, not by scrolling
/// 24 rows of near-identical text.
class _LineSheet extends StatelessWidget {
  const _LineSheet({required this.label, required this.selected});
  final String label;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final groups = <String, List<String>>{};
    for (final code in lineCodes) {
      groups.putIfAbsent(code.substring(0, 2), () => []).add(code);
    }

    return ShadSheet(
      title: Text(label),
      // A bottom sheet insets its bottom edge for the gesture bar and
      // nothing else - by design, since one is not supposed to reach the
      // top. This one does: twenty-four line codes, three to a row, fill a
      // phone. Without a ceiling its title ends up under the clock and the
      // notification icons.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top - 24,
      ),
      // ...and with a ceiling the list has to be able to scroll under it,
      // or a shorter phone clips the last group instead of overlapping the
      // status bar.
      scrollable: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(entry.key, style: theme.textTheme.muted.copyWith(fontWeight: FontWeight.w700)),
              ),
              // Three to a row, every cell the same width. A Wrap sized
              // each chip to its own text, which on four-character codes
              // left a ragged right edge and a different target width per
              // code; a column grid reads as a keypad and gives every code
              // the same, larger target.
              ChipGrid(
                columns: 3,
                children: [
                  for (final code in entry.value)
                    OptionChip(
                      label: code,
                      selected: code == selected,
                      onTap: () => Navigator.of(context).pop(code),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// goods_transport's own free-text "skąd"/"dokąd" - any typed place is
/// accepted (a new one is registered with the order and suggested from then
/// on, see wpsApi's own locations table), with suggestions from every place
/// known so far shown as tappable chips below while typing - same pool,
/// no per-user ranking yet, as wps's own LocationInput.
class FreeTextLocationField extends StatefulWidget {
  const FreeTextLocationField({super.key, required this.label, required this.value, required this.onChanged, required this.suggestions});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> suggestions;

  @override
  State<FreeTextLocationField> createState() => _FreeTextLocationFieldState();
}

class _FreeTextLocationFieldState extends State<FreeTextLocationField> {
  late final _controller = TextEditingController(text: widget.value);
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void didUpdateWidget(FreeTextLocationField old) {
    super.didUpdateWidget(old);
    // The controller was seeded once at init, so a value the *form* changed
    // - swapping skąd/dokąd - would otherwise never reach the text. Guarded
    // against our own onChanged coming back, which would fight the caret
    // mid-word.
    if (widget.value != old.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final needle = _controller.text.trim().toLowerCase();
    final matches = needle.isEmpty
        ? widget.suggestions.take(8).toList()
        : widget.suggestions.where((s) => s.toLowerCase().contains(needle)).take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.muted),
        const SizedBox(height: 6),
        ShadInput(
          controller: _controller,
          focusNode: _focusNode,
          placeholder: Text(widget.label),
          style: theme.textTheme.p.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          onChanged: (v) {
            widget.onChanged(v);
            setState(() {});
          },
        ),
        if (_focused && matches.isNotEmpty) ...[
          const SizedBox(height: 6),
          // Two to a row: these are place names, not four-character
          // codes, so half the width is what keeps one readable.
          ChipGrid(
            columns: 2,
            children: [
              for (final s in matches)
                OptionChip(
                  label: s,
                  onTap: () {
                    _controller.text = s;
                    widget.onChanged(s);
                    _focusNode.unfocus();
                    setState(() {});
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}
