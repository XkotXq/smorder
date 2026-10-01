import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/session/recent_lines_providers.dart';
import '../../core/session/session_providers.dart';
import '../../i18n/gen/strings.g.dart';
import 'cip_materials_field.dart';
import 'item_picker.dart';
import 'location_fields.dart';
import 'photo_field.dart';
import 'order_status.dart';
import 'order_types.dart';
import 'orders_api.dart';

/// One order type's own form - fields built from [OrderTypeConfig.fields],
/// same per-type shape as wps's own NewOrderPanel (OrdersCipListTable.js):
/// - water_refill: to + water (clean/dirty)
/// - material_order: to + productionOrderNo + items
/// - spool_order: to + items
/// - goods_transport: from + to, both free text with suggestions
/// - waste_removal: from (place)
/// - warehouse_return: from (gdzie odebrać)
///
/// No photo field (unlike wps's own form) - see OrdersApi.create's own
/// comment on why that's a dead field everywhere today.
class NewOrderPage extends ConsumerStatefulWidget {
  const NewOrderPage({super.key, required this.typeCode});
  final String typeCode;

  @override
  ConsumerState<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends ConsumerState<NewOrderPage> {
  late final OrderTypeConfig _config = orderTypeConfig(widget.typeCode);

  String _from = '';
  String _to = '';
  String _water = '';
  final _productionOrderNoController = TextEditingController();
  final _noteController = TextEditingController();
  List<ItemRow> _items = [];

  List<String> _locations = [];
  PickedPhoto? _photo;
  /// "Uwagi" starts collapsed - see the field itself.
  bool _noteOpen = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_config.freeText) {
      ref.read(ordersApiProvider).locations().then((locs) {
        if (mounted) setState(() => _locations = locs);
      });
    }
  }

  @override
  void dispose() {
    _productionOrderNoController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isValidPlace {
    // Every type but the free-text goods_transport must be exactly one of
    // the fixed line codes - a LineSelect can itself only ever hold one of
    // those, so this only really guards the freeText case.
    if (!_config.freeText) return true;
    return true; // any non-empty typed text is accepted for goods_transport
  }

  bool get _canSubmit {
    final hasFrom = _config.has(OrderField.from);
    final hasTo = _config.has(OrderField.to);
    if (hasFrom && _from.trim().isEmpty) return false;
    if (hasTo && _to.trim().isEmpty) return false;
    if (hasFrom && hasTo && _from.trim().toLowerCase() == _to.trim().toLowerCase()) return false;
    if (_config.has(OrderField.water) && _water.isEmpty) return false;
    if (_config.has(OrderField.productionOrderNo) && _productionOrderNoController.text.trim().isEmpty) return false;
    if (_config.has(OrderField.items) && _validItems.isEmpty) return false;
    return _isValidPlace;
  }

  List<ItemRow> get _validItems => _items.where((r) {
    final q = double.tryParse(r.quantity.trim().isEmpty ? '1' : r.quantity.trim());
    return q != null && q > 0;
  }).toList();

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final employeeNo = ref.read(sessionProvider).value?.userId ?? '';
      final details = <String, dynamic>{};
      if (_config.has(OrderField.water)) details['water'] = _water;
      if (_config.has(OrderField.productionOrderNo)) details['productionOrderNo'] = _productionOrderNoController.text.trim();

      final order = await ref
          .read(ordersApiProvider)
          .create(
            type: _config.code,
            employeeNo: employeeNo,
            from: _config.has(OrderField.from) ? _from.trim() : null,
            to: _config.has(OrderField.to) ? _to.trim() : null,
            details: details,
            note: _noteController.text.trim(),
            items: _config.has(OrderField.items) ? _validItems.map((r) => r.toNewOrderItem()).toList() : const [],
          );

      // The photo goes up second, under the order's own id (see
      // OrdersApi.uploadPhoto). A failure here must not read as "the order
      // wasn't placed" - it was, and it's already on the forklift
      // operator's list - so this reports the attachment specifically and
      // leaves the operator on the form rather than throwing the order away.
      final photo = _photo;
      if (photo != null) {
        try {
          await ref
              .read(ordersApiProvider)
              .uploadPhoto(
                orderId: order.id,
                bytes: photo.bytes,
                filename: photo.filename,
                contentType: photo.contentType,
                uploadedBy: employeeNo,
              );
        } catch (_) {
          if (!mounted) return;
          setState(() => _error = context.t.orders.newOrder.photoUploadError(orderNo: order.orderNo));
          return;
        }
      }

      // Remembered only now, once the order really exists - a line somebody
      // picked and then abandoned is not a line they order for (see
      // RecentLinesNotifier).
      if (!_config.freeText) {
        final line = (_config.has(OrderField.to) ? _to : _from).trim();
        await ref.read(recentLinesProvider.notifier).remember(line);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = context.t.orders.newOrder.submitError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders;
    final fromLabel = switch (fromLabelFor(_config.code)) {
      FromLabel.place => t.newOrder.fieldPlace,
      FromLabel.collectFrom => t.newOrder.fieldCollectFrom,
      FromLabel.from => t.newOrder.fieldFrom,
    };
    final inRow = _config.has(OrderField.from) && _config.has(OrderField.to);

    Widget fromField() => _config.freeText
        ? FreeTextLocationField(label: fromLabel, value: _from, suggestions: _locations, onChanged: (v) => setState(() => _from = v))
        : LineHeroField(label: fromLabel, value: _from, onChanged: (v) => setState(() => _from = v));

    Widget toField() => _config.freeText
        ? FreeTextLocationField(
            label: t.newOrder.fieldToShort,
            value: _to,
            suggestions: _locations,
            onChanged: (v) => setState(() => _to = v),
          )
        : LineHeroField(label: t.newOrder.fieldTo, value: _to, onChanged: (v) => setState(() => _to = v));

    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              child: Row(
                children: [
                  ShadButton.ghost(onPressed: () => Navigator.of(context).pop(false), child: const Icon(LucideIcons.arrowLeft)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      t.newOrder.titleFor(type: orderTypeLabel(context.t, _config.code)),
                      style: theme.textTheme.h3.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  if (inRow)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: fromField()),
                        Padding(
                          padding: const EdgeInsets.only(top: 34, left: 8, right: 8),
                          child: Icon(LucideIcons.arrowRight, size: 18, color: theme.colorScheme.mutedForeground),
                        ),
                        Expanded(child: toField()),
                      ],
                    )
                  else ...[
                    if (_config.has(OrderField.from)) fromField(),
                    if (_config.has(OrderField.from) && _config.has(OrderField.to)) const SizedBox(height: 16),
                    if (_config.has(OrderField.to)) toField(),
                  ],

                  if (_config.has(OrderField.water)) ...[
                    const SizedBox(height: 16),
                    Text(t.details.water, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _WaterOption(
                          label: t.details.clean,
                          selected: _water == 'clean',
                          onTap: () => setState(() => _water = 'clean'),
                        ),
                        const SizedBox(width: 12),
                        _WaterOption(
                          label: t.details.dirty,
                          selected: _water == 'dirty',
                          onTap: () => setState(() => _water = 'dirty'),
                        ),
                      ],
                    ),
                  ],

                  // "Zamówienie materiału" asks for the production order
                  // first and then lists exactly what that order needs, to
                  // tap - see CipMaterialsField. Every other type with items
                  // searches the whole catalog instead (ItemPicker's own
                  // search box), which is why the picker below only shows it
                  // when there is no production order driving the list.
                  if (_config.has(OrderField.productionOrderNo)) ...[
                    const SizedBox(height: 16),
                    CipMaterialsField(
                      controller: _productionOrderNoController,
                      rows: _items,
                      onRowsChanged: (rows) => setState(() => _items = rows),
                      // The resolved full number lands in the controller the
                      // form already submits; this only rebuilds so the
                      // submit button re-evaluates _canSubmit.
                      onOrderNoResolved: (_) => setState(() {}),
                    ),
                  ],

                  if (_config.has(OrderField.items)) ...[
                    const SizedBox(height: 16),
                    ItemPicker(
                      rows: _items,
                      onChanged: (rows) => setState(() => _items = rows),
                      showSearch: !_config.has(OrderField.productionOrderNo),
                    ),
                  ],

                  if (_config.has(OrderField.photo)) ...[
                    const SizedBox(height: 16),
                    PhotoField(photo: _photo, onChanged: (photo) => setState(() => _photo = photo)),
                  ],

                  // Optional, so it stays one quiet line until somebody
                  // wants it - it used to take as much room as the
                  // destination line, which is the opposite of what it is
                  // worth.
                  const SizedBox(height: 16),
                  if (_noteOpen) ...[
                    Text(t.newOrder.note, style: theme.textTheme.muted),
                    const SizedBox(height: 6),
                    ShadInput(
                      controller: _noteController,
                      placeholder: Text(t.newOrder.notePlaceholder),
                      maxLines: 3,
                    ),
                  ] else
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _noteOpen = true),
                      child: Row(
                        children: [
                          Icon(LucideIcons.plus, size: 16, color: theme.colorScheme.mutedForeground),
                          const SizedBox(width: 6),
                          Text(t.newOrder.noteAdd, style: theme.textTheme.small.copyWith(color: theme.colorScheme.mutedForeground)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // The action lives in a footer, not at the end of the scroll:
            // with a dozen BOM rows on screen the button used to be below
            // the fold, so placing an order meant scrolling to find it.
            // The error sits here too - next to the button that produced it.
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                border: Border(top: BorderSide(color: theme.colorScheme.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.destructive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!, style: theme.textTheme.small.copyWith(color: theme.colorScheme.destructive)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ShadButton(
                      onPressed: _canSubmit && !_submitting ? _submit : null,
                      child: Text(_submitLabel()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Złóż zamówienie", plus how many materials are on it when there are
  /// any - the count is the one thing worth confirming before sending, and
  /// the list itself is usually scrolled above the footer by then.
  String _submitLabel() {
    final t = context.t.orders.newOrder;
    if (!_config.has(OrderField.items) || _validItems.isEmpty) return t.submit;
    return t.submitWithItems(count: _validItems.length);
  }
}

class _WaterOption extends StatelessWidget {
  const _WaterOption({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.accent : null,
          border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: theme.textTheme.p.copyWith(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.mutedForeground,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
