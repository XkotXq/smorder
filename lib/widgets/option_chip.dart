import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// "Tap one of these" - the one shape this app uses for it.
///
/// The new-order form had grown four of these: a recent-line pill, a line
/// code in the picker sheet, clean/dirty water, and a location suggestion.
/// Four radii, four paddings, four border rules, and every one of them
/// between 30 and 44dp tall - under Android's 48dp floor, which is what
/// filling a form in a work glove next to a running line actually runs
/// into. One component, one size, two states.
///
/// Emphasis is not a fifth variant: a chip is selected or it is not, and
/// whether it is the answer or a shortcut to one is carried by where it
/// sits on the form, not by giving it its own padding.
class OptionChip extends StatelessWidget {
  const OptionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.expand = false,
    this.icon,
    this.iconColor,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  /// Fill the row it sits in - for a pair of mutually exclusive answers
  /// (clean/dirty), where splitting the width gives both the largest target
  /// the screen can offer.
  final bool expand;

  /// Optional, and only where it carries meaning the label does not - the
  /// priority bars, whose colour *is* the answer.
  final IconData? icon;

  /// Overrides the chip's own tone for that icon, so a priority keeps its
  /// green/amber/red whether or not the chip is the selected one.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    final chip = Container(
      height: 48,
      // 64 keeps a four-character line code ("ST07") on a target worth
      // aiming at instead of shrink-wrapping the text.
      constraints: const BoxConstraints(minWidth: 64),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.accent : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? (selected ? theme.colorScheme.primary : theme.colorScheme.foreground)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.p.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.foreground,
              ),
            ),
          ),
        ],
      ),
    );

    final tappable = GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: chip);
    return expand ? Expanded(child: tappable) : tappable;
  }
}
