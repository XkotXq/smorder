import 'package:flutter/widgets.dart';

import '../../i18n/gen/strings.g.dart';

/// Shared across this feature's screens - same labels/colours as
/// ../../../smVendor's own order_status.dart (itself mirroring wps's own
/// OrdersCipListTable.js), so an order reads the same everywhere in this
/// app family.

String orderTypeLabel(Translations t, String type) => switch (type) {
  'water_refill' => t.orders.types.water_refill,
  'material_order' => t.orders.types.material_order,
  'spool_order' => t.orders.types.spool_order,
  'goods_transport' => t.orders.types.goods_transport,
  'waste_removal' => t.orders.types.waste_removal,
  'warehouse_return' => t.orders.types.warehouse_return,
  'machine_transport' => t.orders.types.machine_transport,
  _ => type,
};

String orderStatusLabel(Translations t, String status) => switch (status) {
  'new' => t.orders.status.kNew,
  'inProgress' => t.orders.status.inProgress,
  'problem' => t.orders.status.problem,
  'delivered' => t.orders.status.delivered,
  'done' => t.orders.status.done,
  'cancelled' => t.orders.status.cancelled,
  _ => status,
};

const orderStatusColors = {
  'new': (bg: 0xFFEEF2FB, fg: 0xFF22406E), // navy-50 / navy-700
  'inProgress': (bg: 0xFFFFFBEB, fg: 0xFF92400E), // amber-50 / amber-800
  // A blocked order shouts: red-50 / red-700, a shade off 'cancelled' so
  // the two are not mistaken for each other - this one is still open and
  // someone has to act on it.
  'problem': (bg: 0xFFFEF2F2, fg: 0xFFB91C1C),
  'delivered': (bg: 0xFFF0F9FF, fg: 0xFF075985), // sky-50 / sky-800
  'done': (bg: 0xFFECFDF5, fg: 0xFF065F46), // emerald-50 / emerald-800
  'cancelled': (bg: 0xFFFEF2F2, fg: 0xFF991B1B), // red-50 / red-800
};

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status, required this.label});
  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = orderStatusColors[status] ?? orderStatusColors['new']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Color(colors.bg), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: Color(colors.fg), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
