import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../theme/app_colors.dart';

/// Which inputs a "Nowe zamówienie" form needs - mirrors wps's own
/// ORDER_TYPES (OrdersCipListTable.js).
/// `photo` is an optional attachment, not a required input - wps offers one
/// for goods_transport/waste_removal/warehouse_return; here it starts with
/// waste_removal only (adding it to another type is one entry in the list
/// below, now that the whole upload path exists).
enum OrderField { from, to, water, productionOrderNo, items, photo }

class OrderTypeConfig {
  const OrderTypeConfig({
    required this.code,
    required this.fields,
    required this.icon,
    required this.iconLight,
    required this.iconDark,
    this.freeText = false,
  });

  final String code;
  final Set<OrderField> fields;
  final IconData icon;

  /// This type's own icon colour, one per theme - the exact pair WPS uses
  /// for the same type in its "Nowe zamówienie" menu (`text-<c>-600` /
  /// `dark:text-<c>-400`, see ORDER_TYPES in OrdersCipListTable.js), so a
  /// type is recognisable by colour across the web app and here. Pick with
  /// [iconColor].
  final Color iconLight;
  final Color iconDark;

  Color iconColor(Brightness brightness) => brightness == Brightness.dark ? iconDark : iconLight;

  /// true only for goods_transport - "skąd"/"dokąd" there accept any typed
  /// place (registered and suggested from then on), not just the fixed
  /// production lines every other type's from/to is restricted to.
  final bool freeText;

  bool has(OrderField f) => fields.contains(f);
}

/// Same six types (and order) as wps's own "Nowe zamówienie" menu -
/// `machine_transport` exists in wpsApi's schema but isn't offered there
/// either (see wpsApi's AGENTS.md, "Transport orders").
const orderTypes = [
  OrderTypeConfig(
    code: 'water_refill',
    fields: {OrderField.to, OrderField.water},
    icon: LucideIcons.droplets,
    iconLight: AppColors.blue600,
    iconDark: AppColors.blue400,
  ),
  OrderTypeConfig(
    code: 'material_order',
    fields: {OrderField.to, OrderField.productionOrderNo, OrderField.items},
    icon: LucideIcons.package,
    iconLight: AppColors.pink600,
    iconDark: AppColors.pink400,
  ),
  OrderTypeConfig(
    code: 'spool_order',
    fields: {OrderField.to, OrderField.items},
    icon: LucideIcons.spool,
    iconLight: AppColors.gray600,
    // wps pairs this one with neutral-300, not gray-400.
    iconDark: AppColors.neutral300,
  ),
  OrderTypeConfig(
    code: 'goods_transport',
    fields: {OrderField.from, OrderField.to},
    icon: LucideIcons.truck,
    iconLight: AppColors.orange600,
    iconDark: AppColors.orange400,
    freeText: true,
  ),
  OrderTypeConfig(
    code: 'waste_removal',
    fields: {OrderField.from, OrderField.photo},
    icon: LucideIcons.trash2,
    iconLight: AppColors.yellow600,
    iconDark: AppColors.yellow400,
  ),
  OrderTypeConfig(
    code: 'warehouse_return',
    fields: {OrderField.from},
    icon: LucideIcons.undo2,
    iconLight: AppColors.green600,
    iconDark: AppColors.green400,
  ),
];

OrderTypeConfig orderTypeConfig(String code) => orderTypes.firstWhere((t) => t.code == code, orElse: () => orderTypes.first);

/// "skąd" asks a different thing per type - waste_removal's own place, or
/// warehouse_return's "gdzie odebrać" - same FROM_LABEL_KEY idea as wps's
/// own OrdersCipListTable.js (there keyed to a nav.newOrderPanel.fields.*
/// translation; here directly to the translation getter itself since Dart
/// has no dynamic property lookup on a generated translations object).
enum FromLabel { from, place, collectFrom }

FromLabel fromLabelFor(String type) => switch (type) {
  'waste_removal' => FromLabel.place,
  'warehouse_return' => FromLabel.collectFrom,
  _ => FromLabel.from,
};
