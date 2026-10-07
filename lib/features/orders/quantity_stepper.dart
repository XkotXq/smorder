import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// How many of a material to bring: tap to step, or tap the number and type
/// it.
///
/// Both paths matter and neither replaces the other. Stepping is what a
/// thumb in a work glove can do without aiming - the two targets are 48dp,
/// the Android floor, where the plain text field this replaced was a 70px
/// box with a soft keyboard in front of it. Typing is what gets you to 24
/// without 23 taps.
///
/// **Minus at one removes the row.** The icon becomes a bin at that point,
/// so it says so before it happens. One control for "fewer" and "none at
/// all" rather than a separate remove button competing for the same strip
/// of a phone row - and the picker above re-adds a material in one tap.
///
/// Quantities are whole pieces ("szt." - see item_picker.dart's own note:
/// never the catalog's km/kg unit), so stepping is by one and the keyboard
/// is the number pad. A value that arrived with a decimal (an older order
/// being edited) is kept as typed and stepped from its own value rather
/// than being silently rounded.
class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  /// The row's current quantity, as the free text the form submits. Empty
  /// means "not set yet", which counts as one (see ItemRow.toNewOrderItem).
  final String value;
  final ValueChanged<String> onChanged;

  /// Minus, pressed at one. Removing is the honest reading of "zero of
  /// this material".
  final VoidCallback onRemove;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Tapping the number is a request to replace it, not to land a caret in
    // the middle of "12". Selecting on focus means the next keypress is the
    // new quantity.
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      } else if (_controller.text.trim().isEmpty) {
        // Left empty: show the one it is actually worth.
        _controller.text = '1';
        widget.onChanged('1');
      }
    });
  }

  @override
  void didUpdateWidget(QuantityStepper old) {
    super.didUpdateWidget(old);
    // Only when the change came from outside - mirroring our own onChanged
    // back into the controller would fight the caret while typing.
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

  /// The row's quantity as a number. Empty text is one, which is what the
  /// form submits for an untouched row.
  double get _current {
    final text = _controller.text.trim();
    if (text.isEmpty) return 1;
    return double.tryParse(text.replaceAll(',', '.')) ?? 1;
  }

  String _format(double value) {
    // 2, not 2.0 - but a decimal that was already there keeps its shape.
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toString();
  }

  void _step(int by) {
    final next = _current + by;
    if (next < 1) {
      widget.onRemove();
      return;
    }
    final text = _format(next);
    _controller.text = text;
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final atOne = _current <= 1;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            // The bin only at one, where minus means remove.
            icon: atOne ? LucideIcons.trash2 : LucideIcons.minus,
            tone: atOne ? theme.colorScheme.destructive : theme.colorScheme.foreground,
            onTap: () => _step(-1),
          ),
          SizedBox(
            width: 52,
            child: ShadInput(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              // No border of its own: the strip around all three controls
              // is the field. A second rounded box inside this one would be
              // a frame around a frame.
              // ShadDecoration.none, not just a cleared border: it clears the
              // focused and error borders too, so tapping the number does not
              // draw a ring inside the strip.
              decoration: ShadDecoration.none,
              padding: EdgeInsets.zero,
              style: theme.textTheme.p.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              onChanged: widget.onChanged,
            ),
          ),
          _StepButton(
            icon: LucideIcons.plus,
            tone: theme.colorScheme.foreground,
            onTap: () => _step(1),
          ),
        ],
      ),
    );
  }
}

/// 48x48, which is the Android minimum and about the width of a thumb - the
/// icon inside is 18px, but the target is not.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tone, required this.onTap});
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(child: Icon(icon, size: 18, color: tone)),
      ),
    );
  }
}
