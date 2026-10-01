import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';
import 'new_order_page.dart';
import 'order_detail_page.dart';
import 'order_status.dart';
import 'order_types.dart';
import 'orders_api.dart';

/// Same polling cadence/reasoning as ../../../smVendor's own OrdersPage -
/// plain REST polling, not a GraphQL subscription (see that file's own
/// comment).
const _pollInterval = Duration(seconds: 5);

/// Same breakpoint as widgets/app_shell.dart's own `_kWideBreakpoint`.
const _kWideBreakpoint = 600.0;

/// "Zamawianie" - this app's own tab for placing a new transport order and
/// watching every active one through to done/cancelled (read-only past
/// placing it - a forklift operator's own take/deliver actions live in
/// smVendor, not here; what "apka do zamawiania" means, see wpsApi's
/// AGENTS.md "Transport orders"). "Nowe zamówienie" opens the same six
/// types wps's own menu offers (see order_types.dart).
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

enum _LoadStatus { loading, ready, error }

class _OrdersPageState extends ConsumerState<OrdersPage> {
  _LoadStatus _status = _LoadStatus.loading;
  List<TransportOrder> _orders = const [];
  Timer? _pollTimer;
  bool _polling = false;
  // "active" (new + in_progress + delivered) | "history" (done +
  // cancelled) - same split as wps's own "Lista zamówień"/"Historia
  // zamówień" (see wpsapi's STATUS_SETS). A cancelled order (where a
  // "Zgłoś problem" reason actually lands) drops out of "active" the
  // moment it's cancelled, so without this toggle there would be no way
  // to ever see it or its reason again.
  String _scope = 'active';

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _setScope(String scope) {
    if (scope == _scope) return;
    setState(() => _scope = scope);
    _load();
  }

  Future<void> _load() async {
    setState(() => _status = _LoadStatus.loading);
    try {
      final orders = await ref.read(ordersApiProvider).list(_scope);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _status = _LoadStatus.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _LoadStatus.error);
    }
  }

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      final orders = await ref.read(ordersApiProvider).list(_scope);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _status = _LoadStatus.ready;
      });
    } catch (_) {
      // Stay on whatever was last shown - same silent-poll reasoning as
      // ../../../smVendor's own OrdersPage.
    } finally {
      _polling = false;
    }
  }

  Future<void> _openDetail(TransportOrder order) async {
    await Navigator.of(context).push(PageRouteBuilder(pageBuilder: (context, _, _) => OrderDetailPage(orderId: order.id)));
    if (mounted) _load();
  }

  Future<void> _newOrder() async {
    // A drawer up from the bottom - shadcn's own sheet component with
    // side: bottom (ShadSheet, see showShadSheet), which is the phone-shaped
    // way to pick one of six things; a centered dialog is wps's web shape,
    // not this app's.
    final typeCode = await showShadSheet<String>(
      context: context,
      side: ShadSheetSide.bottom,
      builder: (_) => const _OrderTypeSheet(),
    );
    if (typeCode == null || !mounted) return;
    // showShadSheet's future completes as the pop *starts*, while the sheet
    // is still sliding back down (ShadSheet.defaultExitDuration). Pushing
    // the form straight away covered that slide, so the drawer looked like
    // it just vanished - let it finish first.
    await Future<void>.delayed(ShadSheet.defaultExitDuration);
    if (!mounted) return;
    final created = await Navigator.of(
      context,
    ).push<bool>(PageRouteBuilder(pageBuilder: (context, _, _) => NewOrderPage(typeCode: typeCode)));
    if (created == true && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders;

    Widget list;
    if (_status == _LoadStatus.error) {
      list = Center(
        child: Text(t.loadError, style: theme.textTheme.muted.copyWith(color: theme.colorScheme.destructive)),
      );
    } else if (_status == _LoadStatus.loading) {
      list = Center(child: Text(t.loading, style: theme.textTheme.muted));
    } else if (_orders.isEmpty) {
      list = Center(child: Text(t.empty, style: theme.textTheme.muted));
    } else {
      final wide = MediaQuery.sizeOf(context).width >= _kWideBreakpoint;
      list = wide
          ? GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _orders.length,
              itemBuilder: (context, index) => _OrderCard(order: _orders[index], onTap: () => _openDetail(_orders[index])),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _OrderCard(order: _orders[index], onTap: () => _openDetail(_orders[index])),
            );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    _ScopeTab(label: t.scopeActive, selected: _scope == 'active', onTap: () => _setScope('active')),
                    const SizedBox(width: 8),
                    _ScopeTab(label: t.scopeHistory, selected: _scope == 'history', onTap: () => _setScope('history')),
                  ],
                ),
              ),
              Expanded(child: list),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: ShadButton(
            onPressed: _newOrder,
            leading: const Icon(LucideIcons.plus, size: 18),
            child: Text(t.newOrder.button),
          ),
        ),
      ],
    );
  }
}

/// "Aktywne"/"Historia" - see _scope's own comment on why history needs to
/// exist here at all (a cancelled order's "Zgłoś problem" reason is
/// otherwise unreachable).
class _ScopeTab extends StatelessWidget {
  const _ScopeTab({required this.label, required this.selected, required this.onTap});
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.accent : null,
          border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: theme.textTheme.small.copyWith(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.mutedForeground,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// The six order types to pick from, same icons wps's own "Nowe zamówienie"
/// menu uses - pops the chosen type's code, or null if the sheet is
/// dismissed. A bottom sheet (see _newOrder), so every row is a full-width
/// tap target within thumb reach instead of a list inside a centered box.
class _OrderTypeSheet extends StatelessWidget {
  const _OrderTypeSheet();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    return ShadSheet(
      title: Text(t.orders.newOrder.pickType),
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final type in orderTypes)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(type.code),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      // Each type's own colour, same pair wps's menu uses -
                      // see OrderTypeConfig.iconColor.
                      Icon(type.icon, size: 22, color: type.iconColor(theme.brightness)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(orderTypeLabel(t, type.code), style: theme.textTheme.p.copyWith(fontSize: 16)),
                      ),
                      Icon(LucideIcons.chevronRight, size: 18, color: theme.colorScheme.mutedForeground),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});
  final TransportOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final rootT = context.t;
    final t = rootT.orders;
    // An order blocked on *this* person gets a red outline: this list is
    // how they find out at all (there are no push notifications - the user
    // chose in-app only), so it has to be visible without reading. A
    // problem they reported themselves is shown but not outlined - it is
    // with the forklift operator, not with them.
    final needsMe = order.awaitingProblemResolution;
    final blocked = order.hasOpenProblem;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: needsMe ? theme.colorScheme.destructive : theme.colorScheme.border,
            width: needsMe ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Where it goes is the headline, not the order number: glancing
            // at this list answers "is my transport coming", and
            // "B216/260930/809" is machine identity - useful to quote, never
            // what you recognise an order by. The type is carried by its own
            // coloured icon (the same colour wps gives it), so it needs no
            // separate line of text either.
            Row(
              children: [
                Icon(
                  orderTypeConfig(order.type).icon,
                  size: 18,
                  color: orderTypeConfig(order.type).iconColor(theme.brightness),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.route(),
                    style: theme.textTheme.p.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                OrderStatusBadge(status: order.status, label: orderStatusLabel(rootT, order.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              orderTypeLabel(rootT, order.type),
              style: theme.textTheme.muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (order.note != '-' && order.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(order.note, style: theme.textTheme.small, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            // A blocked order says what is wrong, and - when it is this
            // person's turn - that something is expected of them. The card
            // is where they learn about it, so it carries the ask too.
            if (blocked) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.triangleAlert, size: 14, color: theme.colorScheme.destructive),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.problemNote.isNotEmpty)
                          Text(
                            order.problemNote,
                            style: theme.textTheme.small.copyWith(
                              color: theme.colorScheme.destructive,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          needsMe ? t.card.problemNeedsYou : t.card.problemWithVendor,
                          style: theme.textTheme.muted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            // A quick-glance hint that this one was cancelled over a
            // reported problem, without needing to open it - see
            // OrderDetailPage's own full banner for the complete text.
            if (order.status == 'cancelled' && (order.cancelReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(LucideIcons.triangleAlert, size: 14, color: theme.colorScheme.destructive),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.cancelReason!,
                      style: theme.textTheme.small.copyWith(color: theme.colorScheme.destructive),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // The footer carries identity and provenance - the things you
            // need once you have found the order, not to find it: who asked
            // (left) and the order number (right, demoted to muted small
            // from the heading it used to be).
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${t.card.employeeNo}: ${order.employeeNo.isEmpty ? '-' : order.employeeNo}',
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(order.orderNo, style: theme.textTheme.muted.copyWith(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
