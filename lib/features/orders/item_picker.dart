import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/sm_catalog_api.dart';
import '../../i18n/gen/strings.g.dart';
import 'orders_api.dart';
import 'quantity_stepper.dart';

/// One added row - quantity is kept as free text while editing (same
/// "blank defaults to 1 at submit" rule as wps's own validRows) rather than
/// parsed on every keystroke.
class ItemRow {
  /// A row starts at one: adding a material is already the statement
  /// that one is wanted, and an empty box asked every row to be answered
  /// twice. The stepper's own minus removes it, so "none" is still one tap
  /// away (see QuantityStepper).
  ItemRow({required this.itemNo, required this.itemName, this.quantity = '1'});
  final String itemNo;
  final String itemName;
  String quantity;

  NewOrderItem toNewOrderItem() {
    final trimmed = quantity.trim();
    return NewOrderItem(itemNo: itemNo, itemName: itemName, quantity: trimmed.isEmpty ? '1' : trimmed);
  }
}

/// Adds materials to a material_order/spool_order - search the catalog by
/// item number or name, tap a match to add it as a row below with its own
/// quantity stepper, which also takes a typed number and removes the row
/// when minus is pressed at one (see QuantityStepper)
/// (order_items are always counted by piece, "szt." - see
/// wpsApi's AGENTS.md, "Transport orders"; never the catalog's own km/kg
/// unit). Same search/add shape as wps's own NewOrderPanel, minus its
/// CIP-order-scoped picker for material_order specifically (orderMatches) -
/// this always searches the full sm_catalog, a reasonable first cut.
class ItemPicker extends ConsumerStatefulWidget {
  const ItemPicker({super.key, required this.rows, required this.onChanged, this.showSearch = true});

  final List<ItemRow> rows;
  final ValueChanged<List<ItemRow>> onChanged;

  /// Whether to offer the catalog search box. False for "Zamówienie
  /// materiału", where materials are picked from the production order's own
  /// BOM instead (see cip_materials_field.dart) and this widget is only here
  /// to list what was picked, with a quantity field per row.
  final bool showSearch;

  @override
  ConsumerState<ItemPicker> createState() => ItemPickerState();
}

class ItemPickerState extends ConsumerState<ItemPicker> {
  final _searchController = TextEditingController();
  List<SmCatalogItem> _catalog = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(smCatalogApiProvider)
        .list()
        .then((items) {
          if (!mounted) return;
          setState(() {
            _catalog = items;
            _loaded = true;
          });
        })
        .catchError((_) {
          if (mounted) setState(() => _loaded = true);
        });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _add(SmCatalogItem item) {
    widget.onChanged([...widget.rows, ItemRow(itemNo: item.itemNo, itemName: item.itemName)]);
    _searchController.clear();
    setState(() {});
  }

  void _removeAt(int index) {
    final next = [...widget.rows]..removeAt(index);
    widget.onChanged(next);
  }

  void _setQuantity(int index, String value) {
    widget.rows[index].quantity = value;
    widget.onChanged(widget.rows);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.newOrder;
    final needle = _searchController.text.trim().toLowerCase();
    final shown = widget.rows.map((r) => r.itemNo).toSet();
    final matches = needle.isEmpty
        ? const <SmCatalogItem>[]
        : _catalog
              .where((c) => !shown.contains(c.itemNo))
              .where((c) => c.itemNo.toLowerCase().contains(needle) || c.itemName.toLowerCase().contains(needle))
              .take(8)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSearch) ...[
        Text(t.items, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ShadInput(
          controller: _searchController,
          placeholder: Text(t.itemSearchPlaceholder),
          leading: const Padding(padding: EdgeInsets.only(left: 4), child: Icon(LucideIcons.search, size: 16)),
          onChanged: (_) => setState(() {}),
        ),
        ],
        if (widget.showSearch && needle.isNotEmpty && matches.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in matches)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _add(c),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${c.itemName} ', style: theme.textTheme.small, overflow: TextOverflow.ellipsis),
                          ),
                          Text(c.itemNo, style: theme.textTheme.muted.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          )
        else if (widget.showSearch && needle.isNotEmpty && _loaded && matches.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(t.itemSearchEmpty, style: theme.textTheme.muted.copyWith(fontSize: 12)),
          ),
        if (widget.rows.isNotEmpty) ...[
          SizedBox(height: widget.showSearch ? 12 : 0),
          // "Do przywiezienia" - what is actually being ordered, as opposed
          // to what the production order merely needs (the list above, see
          // cip_materials_field.dart). The two used to be identical
          // bordered boxes one under the other, which is unreadable at a
          // glance: this one is **filled** in the accent colour and the
          // source list is flat, so "offered" vs "chosen" is a difference
          // in shape, not just in two similar headings.
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(t.itemsChosen, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.accent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < widget.rows.length; i++) ...[
                  // A hairline of the accent border, not the neutral one -
                  // the neutral grey disappears on this filled background.
                  if (i > 0) Container(height: 1, color: theme.colorScheme.primary.withValues(alpha: 0.18)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.rows[i].itemName,
                                style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(widget.rows[i].itemNo, style: theme.textTheme.muted.copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        QuantityStepper(
                          // Keyed by the material, not the index: removing a
                          // row above this one must not hand its controller
                          // (and its number) to a different material.
                          key: ValueKey(widget.rows[i].itemNo),
                          value: widget.rows[i].quantity,
                          onChanged: (v) => _setQuantity(i, v),
                          onRemove: () => _removeAt(i),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
