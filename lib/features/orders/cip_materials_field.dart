import 'package:flutter/material.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/auth_api.dart';
import '../../core/api/cip_orders_api.dart';
import '../../core/session/session_providers.dart';
import '../../i18n/gen/strings.g.dart';
import 'item_picker.dart';

/// "Zamówienie materiału": the production order number, and the materials
/// CIP says that order needs - tap one to put it on the transport order.
///
/// The number does not have to be complete: CIP resolves a fragment or just
/// the ending of one (e.g. the last 6 digits) to the real orderId(s) - see
/// wpsApi's AGENTS.md, "Order lookup". Whatever it resolves to is written
/// back into the field, so the order is stored under the real number rather
/// than the fragment somebody typed.
///
/// Unlike wps, which offers this as an input with a dropdown of suggestions,
/// here the BOM is simply listed: on a phone a list of a handful of rows is
/// easier to hit than a type-ahead.
class CipMaterialsField extends ConsumerStatefulWidget {
  const CipMaterialsField({
    super.key,
    required this.controller,
    required this.rows,
    required this.onRowsChanged,
    required this.onOrderNoResolved,
  });

  /// The productionOrderNo field - owned by the form, since it is submitted
  /// with the order (`details.productionOrderNo`).
  final TextEditingController controller;

  /// The materials already on the order being built - a row already added is
  /// shown as added rather than offered twice.
  final List<ItemRow> rows;
  final ValueChanged<List<ItemRow>> onRowsChanged;

  /// Called with the full orderId CIP resolved, so the form keeps the real
  /// number instead of the typed fragment.
  final ValueChanged<String> onOrderNoResolved;

  @override
  ConsumerState<CipMaterialsField> createState() => _CipMaterialsFieldState();
}

enum _Status { idle, loading, loaded, error }

class _CipMaterialsFieldState extends ConsumerState<CipMaterialsField> {
  _Status _status = _Status.idle;
  List<CipOrderLine> _lines = const [];
  String? _error;

  /// What the last lookup was for - re-searching the same text is a no-op
  /// instead of another live CIP round trip (the same guard wps's own form
  /// keeps, see its lastFetchedOrderNoRef).
  String? _searchedFor;

  Future<void> _search() async {
    final typed = widget.controller.text.trim();
    if (typed.isEmpty || _status == _Status.loading) return;
    if (typed == _searchedFor && _status == _Status.loaded) return;

    setState(() {
      _status = _Status.loading;
      _error = null;
    });

    final t = context.t.orders.newOrder;
    try {
      final token = await ref.read(sessionProvider.notifier).freshCipToken(() => ref.read(authApiProvider));
      if (token == null) {
        if (mounted) {
          setState(() {
            _status = _Status.error;
            _error = t.cipSessionExpired;
          });
        }
        return;
      }
      var lines = await _lookup(typed, token);
      if (!mounted) return;

      // Drop lines whose BOM has nothing this warehouse stocks - the
      // endpoint already filters the materials, so such a line would only be
      // an empty heading.
      lines = lines.where((l) => l.materials.isNotEmpty).toList();
      setState(() {
        _lines = lines;
        _searchedFor = typed;
        _status = _Status.loaded;
        _error = lines.isEmpty ? t.cipNoMaterials : null;
      });

      final resolved = _resolvedOrderNo(lines, typed);
      if (resolved != typed) {
        widget.controller.text = resolved;
        widget.onOrderNoResolved(resolved);
        _searchedFor = resolved;
      }
    } on CipLookupFailure catch (f) {
      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _error = switch (f.kind) {
          CipLookupError.noSession => t.cipSessionExpired,
          CipLookupError.notFound => t.cipOrderNotFound,
          CipLookupError.unreachable => t.cipUnreachable,
        };
      });
    }
  }

  /// One retry on an expired CIP session: wpsApi answers 401 both when no
  /// token was sent and when CIP refused the one that was, and a token that
  /// looked unexpired locally can still be dead (somebody logged in
  /// elsewhere, CIP restarted, ...). So a first 401 invalidates the stored
  /// token and tries once more with a refreshed one, rather than sending the
  /// operator back to the login screen for something recoverable.
  Future<List<CipOrderLine>> _lookup(String orderId, String token) async {
    final api = ref.read(cipOrdersApiProvider);
    try {
      return await api.warehouseMaterials(orderId: orderId, cipToken: token);
    } on CipLookupFailure catch (f) {
      if (f.kind != CipLookupError.noSession) rethrow;
      await ref.read(sessionProvider.notifier).invalidateCipToken();
      final renewed = await ref.read(sessionProvider.notifier).freshCipToken(() => ref.read(authApiProvider));
      if (renewed == null) rethrow;
      return api.warehouseMaterials(orderId: orderId, cipToken: renewed);
    }
  }

  /// The number to keep: the one exact orderId when everything resolved to
  /// one, otherwise their shared base number without the "(line)" suffix -
  /// same rule as wps's own resolvedOrderLabelFromIds.
  String _resolvedOrderNo(List<CipOrderLine> lines, String fallback) {
    final ids = <String>{for (final l in lines) if (l.orderId.isNotEmpty) l.orderId}.toList();
    if (ids.isEmpty) return fallback;
    if (ids.length == 1) return ids.first;
    final base = ids.first.replaceFirst(RegExp(r'\(\d+\)$'), '');
    return ids.every((id) => id.startsWith(base)) ? base : fallback;
  }

  void _add(CipOrderMaterial m) {
    if (widget.rows.any((r) => r.itemNo == m.itemCode)) return;
    widget.onRowsChanged([...widget.rows, ItemRow(itemNo: m.itemCode, itemName: m.name)]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.newOrder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.orders.details.productionOrderNo,
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(t.cipOrderNoHint, style: theme.textTheme.muted.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ShadInput(
                controller: widget.controller,
                placeholder: Text(t.cipOrderNoPlaceholder),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                // Typing again drops a list that no longer matches the field,
                // so materials from a previous number are never offered as if
                // they belonged to this one.
                onChanged: (_) {
                  if (_status != _Status.idle) setState(() => _status = _Status.idle);
                },
              ),
            ),
            const SizedBox(width: 8),
            ShadButton.outline(
              onPressed: _status == _Status.loading ? null : _search,
              leading: const Icon(LucideIcons.search, size: 18),
              child: Text(_status == _Status.loading ? t.cipSearching : t.cipSearch),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.small.copyWith(color: theme.colorScheme.destructive)),
        ],
        if (_status == _Status.loaded && _lines.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(t.cipMaterialsTitle, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          for (final line in _lines) ...[
            // Only worth naming the line when the typed number matched more
            // than one of them.
            if (_lines.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  line.segDescription == null ? line.orderId : '${line.orderId} - ${line.segDescription}',
                  style: theme.textTheme.muted.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            // Flat rows on the page background, deliberately **not** a
            // bordered card: the chosen-materials list below is the filled
            // one (see item_picker.dart). Two identical boxes stacked is
            // what this looked like before, and you could not tell which
            // was "offered" and which was "ordered" without reading both
            // headings.
            Column(
              children: [
                for (var i = 0; i < line.materials.length; i++) ...[
                  if (i > 0) Container(height: 1, color: theme.colorScheme.border),
                  _MaterialRow(
                    material: line.materials[i],
                    added: widget.rows.any((r) => r.itemNo == line.materials[i].itemCode),
                    onTap: () => _add(line.materials[i]),
                  ),
                ],
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.material, required this.added, required this.onTap});
  final CipOrderMaterial material;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.newOrder;
    final qty = material.requiredQuantity;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: added ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              added ? LucideIcons.circleCheck : LucideIcons.circlePlus,
              size: 20,
              color: added ? theme.colorScheme.primary : theme.colorScheme.mutedForeground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(material.name, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(material.itemCode, style: theme.textTheme.muted.copyWith(fontSize: 11)),
                  if (material.changedFrom != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      t.cipChangedFrom(from: material.changedFrom!),
                      style: theme.textTheme.muted.copyWith(fontSize: 11, color: theme.colorScheme.primary),
                    ),
                  ],
                ],
              ),
            ),
            // How much the production order needs, in its own right-hand
            // column so the figures line up down the list - rather than
            // joined onto the item number as one meta string.
            if (qty != null) ...[
              const SizedBox(width: 10),
              Text(
                '${_trim(qty)} ${material.unit}'.trim(),
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "2.500" -> "2.5", "3.000" -> "3" - CIP quantities carry trailing zeros
/// that say nothing here.
String _trim(double v) {
  var s = v.toStringAsFixed(3);
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return s;
}
