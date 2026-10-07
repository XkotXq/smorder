import 'package:flutter/widgets.dart';

/// A fixed number of equal columns, filled left to right.
///
/// Flutter's Wrap sizes each child to its own content, which is right for a
/// sentence of tags and wrong for a set of answers: four-character line
/// codes came out as a ragged right edge where every target was a different
/// width, and the widest row decided nothing. Here every cell is the same
/// width, so the sheet reads as a keypad - and each code gets a third of
/// the screen rather than shrink-wrapping to its text.
///
/// Not a GridView: this is a handful of items inside an already-scrolling
/// sheet, where a scroll view inside a scroll view needs shrinkWrap and a
/// disabled physics to behave. Rows of Expanded children do the same job
/// with no such coupling, and a short last row keeps the column widths
/// instead of letting one child stretch across (its slots are left empty).
class ChipGrid extends StatelessWidget {
  const ChipGrid({
    super.key,
    required this.children,
    this.columns = 3,
    this.spacing = 8,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final slice = children.sublist(start, (start + columns).clamp(0, children.length));
      rows.add(
        Row(
          // The chips carry their own 48dp height; the row only has to
          // line them up.
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              // The empty slots of a short last row, so three items and
              // four do not sit on different column widths.
              Expanded(child: i < slice.length ? slice[i] : const SizedBox.shrink()),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          rows[i],
        ],
      ],
    );
  }
}
