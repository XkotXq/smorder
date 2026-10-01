import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/session/recent_lines_providers.dart';
import '../../i18n/gen/strings.g.dart';
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
/// beats a dropdown.
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
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final line in recent) _RecentChip(line: line, onTap: () => onChanged(line))],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A previously used line. Deliberately quieter than the hero block - it is
/// a shortcut, not the current answer.
class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.line, required this.onTap});
  final String line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Text(line, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
      ),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final code in entry.value)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(context).pop(code),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: code == selected ? theme.colorScheme.accent : null,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: code == selected ? theme.colorScheme.primary : theme.colorScheme.border,
                          ),
                        ),
                        child: Text(
                          code,
                          style: theme.textTheme.p.copyWith(
                            fontWeight: FontWeight.w600,
                            color: code == selected ? theme.colorScheme.primary : null,
                          ),
                        ),
                      ),
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
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in matches)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _controller.text = s;
                    widget.onChanged(s);
                    _focusNode.unfocus();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(s, style: theme.textTheme.small),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
