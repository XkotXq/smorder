import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/session/session_providers.dart';
import '../../i18n/gen/strings.g.dart';
import 'order_status.dart';
import 'order_types.dart';
import 'orders_api.dart';

const _pollInterval = Duration(seconds: 3);

/// One order's own page, read-only - this app places orders and watches
/// their status through to done/cancelled, it doesn't act on them (a
/// forklift operator's own take/deliver/accept-or-report-problem actions
/// live in smVendor and wps, not here - see wpsApi's AGENTS.md "Transport
/// orders"). Live (polled - see _pollInterval), same pattern as
/// ../../../smVendor's own OrderDetailPage, minus every action button.
class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

enum _LoadStatus { loading, ready, error }

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  _LoadStatus _status = _LoadStatus.loading;
  TransportOrder? _order;
  Timer? _pollTimer;
  bool _polling = false;
  bool _acting = false; // accept()/reportProblem() in flight
  String? _actionError;

  /// Seconds until the auto-accept, ticked down locally once a second so the
  /// number moves smoothly, and re-synced from the server on every poll (see
  /// _syncCountdown). The server owns the real deadline - this is only the
  /// display between reads, so a phone with a skewed clock still shows the
  /// right time and the 10-minute window lives in exactly one place.
  int? _secondsLeft;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    // One second, always running: cheap, and it means the countdown starts
    // moving the moment an order turns up delivered without having to
    // start/stop a timer on every status change.
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Takes the server's remaining-seconds as the truth on every read - so
  /// local ticking can never drift, it only fills the 3 s gaps between
  /// polls.
  void _syncCountdown(TransportOrder order) => _secondsLeft = order.autoAcceptInSeconds;

  void _tick() {
    final left = _secondsLeft;
    if (left == null || left <= 0) return;
    setState(() => _secondsLeft = left - 1);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _status = _LoadStatus.loading);
    try {
      final order = await ref.read(ordersApiProvider).get(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _syncCountdown(order);
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
      final order = await ref.read(ordersApiProvider).get(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _syncCountdown(order);
        _status = _LoadStatus.ready;
      });
    } catch (_) {
      // Stay on whatever was last shown.
    } finally {
      _polling = false;
    }
  }

  /// "Zgadza się" - delivered -> done. Nothing to navigate afterwards: the
  /// page keeps showing the order, now closed, and the action row is gone
  /// because the status it depends on changed.
  Future<void> _accept() async {
    setState(() {
      _acting = true;
      _actionError = null;
    });
    try {
      final updated = await ref
          .read(ordersApiProvider)
          .accept(widget.orderId, ref.read(sessionProvider).value?.userId ?? '');
      if (!mounted) return;
      setState(() {
        _order = updated;
        _syncCountdown(updated);
        _acting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _acting = false;
        _actionError = context.t.orders.detail.acceptError;
      });
    }
  }

  /// "Problem rozwiązany" - problem -> in_progress, unblocking the forklift
  /// operator, who is then shown "Dostarczone"/"Zgłoś problem" again. No
  /// dialog: the point is that this is the one tap that gets the transport
  /// moving, so asking for text first would only make the slower answer
  /// (doing nothing, or chatting) the easier one.
  Future<void> _resolveProblem() async {
    setState(() {
      _acting = true;
      _actionError = null;
    });
    try {
      final updated = await ref
          .read(ordersApiProvider)
          .resolveProblem(widget.orderId, resolvedBy: ref.read(sessionProvider).value?.userId ?? '');
      if (!mounted) return;
      setState(() {
        _order = updated;
        _syncCountdown(updated);
        _acting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _acting = false;
        _actionError = context.t.orders.detail.resolveError;
      });
    }
  }

  /// "Zgłoś problem" on a delivered order - `delivered -> problem`, which
  /// hands it to the forklift operator to put right (it used to cancel the
  /// order outright, ending it with nobody to answer). A dismissed dialog
  /// (null) reports nothing.
  Future<void> _reportProblem() async {
    final reason = await showShadDialog<String>(context: context, builder: (_) => const _ReportProblemDialog());
    if (reason == null || reason.isEmpty || !mounted) return;
    setState(() {
      _acting = true;
      _actionError = null;
    });
    try {
      final updated = await ref.read(ordersApiProvider).reportProblem(
        widget.orderId,
        reportedBy: ref.read(sessionProvider).value?.userId ?? '',
        note: reason,
      );
      if (!mounted) return;
      setState(() {
        _order = updated;
        _syncCountdown(updated);
        _acting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _acting = false;
        _actionError = context.t.orders.detail.problemError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;

    Widget body;
    if (_status == _LoadStatus.loading) {
      body = Center(child: Text(t.orders.loading, style: theme.textTheme.muted));
    } else if (_status == _LoadStatus.error || _order == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.orders.loadError, style: theme.textTheme.muted.copyWith(color: theme.colorScheme.destructive), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ShadButton.outline(onPressed: _load, child: Text(t.orders.retry)),
            ],
          ),
        ),
      );
    } else {
      body = _OrderDetailBody(order: _order!);
    }

    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              child: Row(
                children: [
                  ShadButton.ghost(onPressed: () => Navigator.of(context).pop(), child: const Icon(LucideIcons.arrowLeft)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _order?.orderNo ?? '...',
                      style: theme.textTheme.h3.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_order != null) OrderStatusBadge(status: _order!.status, label: orderStatusLabel(t, _order!.status)),
                ],
              ),
            ),
            Expanded(child: body),
            // The two answers live in a footer, within thumb reach and
            // always visible - the detail list above can be long (items,
            // photo), and this is the one screen where the action is the
            // reason for opening it.
            if (_order?.awaitingConfirmation ?? false)
              _ConfirmationFooter(
                secondsLeft: _secondsLeft,
                acting: _acting,
                error: _actionError,
                onAccept: _accept,
                onReportProblem: _reportProblem,
              )
            // A problem that waits on *this* person gets the same footer
            // slot as the confirmation - the two states never overlap. One
            // they reported themselves shows no footer: the banner already
            // says it is with the operator.
            else if (_order?.awaitingProblemResolution ?? false)
              _ProblemFooter(acting: _acting, error: _actionError, onResolve: _resolveProblem),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.order});

  final TransportOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.detail;

    Widget infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.muted)),
          Flexible(
            child: Text(value, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.right),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // The headline: where it goes, and what kind of transport it is in
        // its own colour. Same reasoning as the list card - the route is
        // what this order *is* to the person who placed it.
        Row(
          children: [
            Icon(
              orderTypeConfig(order.type).icon,
              size: 22,
              color: orderTypeConfig(order.type).iconColor(theme.brightness),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.route(),
                    style: theme.textTheme.h3.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(orderTypeLabel(context.t, order.type), style: theme.textTheme.muted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // A reported problem is the most important thing on this screen, so
        // it comes before the detail rows rather than after them.
        if (order.hasOpenProblem) ...[
          _ProblemBanner(
            // Whose problem it is changes what this says, and it is the
            // first thing the person needs to know: one of the two is
            // "somebody is waiting on you".
            title: order.awaitingProblemResolution ? t.problemFromVendor : t.problemMine,
            note: order.problemNote.isEmpty ? '-' : order.problemNote,
            by: order.problemReportedBy,
            at: order.problemReportedAt,
            footnote: order.awaitingProblemResolution ? null : t.problemWaitingOnVendor,
          ),
          const SizedBox(height: 16),
        ] else if (order.status == 'cancelled' && (order.cancelReason ?? '').isNotEmpty) ...[
          _ProblemBanner(title: t.problemReported, note: order.cancelReason!, at: order.cancelledAt),
          const SizedBox(height: 16),
        ] else if (order.problemResolvedAt != null) ...[
          // Not a problem any more, but worth saying it happened: the
          // transport was held up and this person is the one who released
          // it. The full sequence is in the order's own events.
          _ResolvedNotice(order: order),
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.productionOrderNo != null) infoRow(t.productionOrderNo, order.productionOrderNo!),
              if (order.water != null)
                infoRow(
                  context.t.orders.details.water,
                  order.water == 'clean' ? context.t.orders.details.clean : context.t.orders.details.dirty,
                ),
              // "Zlecający" and "Zrealizował" are always both here, even as
              // "-" on an order nobody has touched yet - they're the pair
              // that says who asked and who did it.
              infoRow(t.employeeNo, order.employeeNo.isEmpty ? '-' : order.employeeNo),
              // wpsApi's own fulfilledBy is already delivered_by || taken_by
              // (|| the closer - see its orderRowToApi), so these two
              // usually repeat it exactly; show them only when a *different*
              // employee took or delivered it than the one "Zrealizował"
              // credits, rather than printing the same number three times.
              if (order.takenBy != null && order.takenBy != order.fulfilledBy) infoRow(t.takenBy, order.takenBy!),
              if (order.deliveredBy != null && order.deliveredBy != order.fulfilledBy)
                infoRow(t.deliveredBy, order.deliveredBy!),
              infoRow(t.fulfilledBy, order.fulfilledBy),
              infoRow(t.createdAt, _formatDateTime(order.createdAt)),
              if (order.note != '-' && order.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(order.note, style: theme.textTheme.p),
              ],
            ],
          ),
        ),
        // The attachment, if the order was placed with one (see
        // features/orders/photo_field.dart). The URL is a presigned link
        // that wpsApi re-issues on every read, so it needs no auth header
        // and must not be cached.
        if (order.photoUrl != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              order.photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.border),
                ),
                child: Text(t.photoUnavailable, style: theme.textTheme.muted),
              ),
            ),
          ),
        ],
        if (order.items.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(t.itemsTitle, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < order.items.length; i++) ...[
                  if (i > 0) Container(height: 1, color: theme.colorScheme.border),
                  _OrderItemTile(item: order.items[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// What a delivered order is waiting for: the requester confirming it, or
/// reporting what is wrong. Neither is mandatory - wpsApi closes the order
/// on its own once the window runs out, and saying so is the point of the
/// countdown: it turns "an unanswered screen" into "doing nothing is also
/// an answer", which is how this actually works on the floor.
///
/// [secondsLeft] comes from the server and is ticked down locally by the
/// page (see _tick/_syncCountdown), so the number moves every second
/// without trusting the phone's own clock for the deadline.
class _ConfirmationFooter extends StatelessWidget {
  const _ConfirmationFooter({
    required this.secondsLeft,
    required this.acting,
    required this.error,
    required this.onAccept,
    required this.onReportProblem,
  });

  final int? secondsLeft;
  final bool acting;
  final String? error;
  final VoidCallback onAccept;
  final VoidCallback onReportProblem;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.detail;
    final left = secondsLeft;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clock, size: 14, color: theme.colorScheme.mutedForeground),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  left == null ? t.autoAcceptPlain : t.autoAcceptIn(time: _formatLeft(left)),
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: theme.textTheme.small.copyWith(color: theme.colorScheme.destructive)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ShadButton.outline(
                    onPressed: acting ? null : onReportProblem,
                    child: Text(t.reportProblem),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ShadButton(onPressed: acting ? null : onAccept, child: Text(t.accept)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "9:05", or "0:00" in the gap between the window closing and the
  /// server's sweep actually running.
  String _formatLeft(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// The description for "Zgłoś problem", popped as the dialog's result; null
/// means dismissed and nothing should happen.
///
/// **Required**, enforced here and in wpsApi: the forklift operator is being
/// asked to put something right, and a problem nobody can read is not a
/// report. So "Zgłoś" stays disabled until something is typed.
class _ReportProblemDialog extends StatefulWidget {
  const _ReportProblemDialog();

  @override
  State<_ReportProblemDialog> createState() => _ReportProblemDialogState();
}

class _ReportProblemDialogState extends State<_ReportProblemDialog> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.orders.detail;
    return ShadDialog(
      title: Text(t.problemTitle),
      description: Text(t.problemDescription),
      actions: [
        ShadButton.outline(onPressed: () => Navigator.of(context).pop(), child: Text(t.problemCancel)),
        ShadButton.destructive(
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(t.problemSubmit),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ShadInput(controller: _controller, placeholder: Text(t.problemPlaceholder), maxLines: 3),
      ),
    );
  }
}

/// What is (or was) wrong with this transport, above the order's detail
/// rows: *why* it is stuck or was cancelled matters more than any of them.
///
/// Used for both kinds of problem, which look the same to the person
/// reading them but are not the same thing: the forklift operator's own
/// `problem` status (the order is open and waiting on this app - see
/// TransportOrder.problemNote) and a cancellation's `cancel_reason` (the
/// order is closed).
class _ProblemBanner extends StatelessWidget {
  const _ProblemBanner({required this.title, required this.note, this.by, this.at, this.footnote});
  final String title;
  final String note;
  final String? by;
  final DateTime? at;

  /// What happens next, when this person is not the one who has to act -
  /// otherwise a red banner with no button reads as a dead end.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final stamp = [
      if ((by ?? '').isNotEmpty) context.t.orders.detail.problemBy(who: by!),
      if (at != null) _formatDateTime(at!),
    ].join(' - ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.destructive.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.triangleAlert, size: 18, color: theme.colorScheme.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.destructive),
                ),
                const SizedBox(height: 4),
                Text(note, style: theme.textTheme.p),
                if (stamp.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(stamp, style: theme.textTheme.muted.copyWith(fontSize: 12)),
                ],
                if (footnote != null) ...[
                  const SizedBox(height: 6),
                  Text(footnote!, style: theme.textTheme.small.copyWith(fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Problem rozwiązany" after the fact - a quiet green note, not an alarm:
/// the transport is moving again, this only records that it was held up.
class _ResolvedNotice extends StatelessWidget {
  const _ResolvedNotice({required this.order});
  final TransportOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.detail;
    // emerald-700/-50, the same pair order_status.dart uses for 'done'.
    const fg = Color(0xFF047857);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.circleCheck, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.problemResolvedTitle, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(height: 4),
                Text(
                  [
                    if ((order.problemResolvedBy ?? '').isNotEmpty) t.problemBy(who: order.problemResolvedBy!),
                    if (order.problemResolvedAt != null) _formatDateTime(order.problemResolvedAt!),
                  ].join(' - '),
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What a blocked order (`problem`) is waiting for: this person either
/// sorting out whatever is wrong and saying so, or talking it over.
///
/// Two answers, deliberately unequal. **"Problem rozwiązany"** is the
/// primary one and the only one that moves the transport - pressing it puts
/// the order back to in_progress and the forklift operator is told to carry
/// on. **"Czat"** is secondary and not built yet (the user deferred it), so
/// it is disabled and labelled as coming - shown rather than hidden because
/// it is the pair that makes the primary button an obvious choice instead of
/// the only one.
class _ProblemFooter extends StatelessWidget {
  const _ProblemFooter({required this.acting, required this.error, required this.onResolve});

  final bool acting;
  final String? error;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.detail;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(LucideIcons.triangleAlert, size: 14, color: theme.colorScheme.destructive),
              const SizedBox(width: 6),
              Expanded(child: Text(t.problemWaitingOnYou, style: theme.textTheme.muted.copyWith(fontSize: 12))),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: theme.textTheme.small.copyWith(color: theme.colorScheme.destructive)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ShadButton.outline(
                    onPressed: null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.chat),
                        Text(t.chatSoon, style: theme.textTheme.muted.copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ShadButton(onPressed: acting ? null : onResolve, child: Text(t.problemResolve)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});
  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final fulfilled = item.isFulfilled;
    final required = '${item.quantity} ${item.unit}'.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // The ticked circle is the only thing that marks a material as
          // issued here - no strikethrough, no dimmed text (unlike
          // ../../../smVendor's own tile, where the list is a working
          // checklist being ticked off). This app only *reads* the order,
          // so a finished one must stay as legible as a pending one.
          Icon(
            fulfilled ? LucideIcons.circleCheck : LucideIcons.circle,
            size: 20,
            color: fulfilled ? theme.colorScheme.primary : theme.colorScheme.mutedForeground,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemName, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(item.itemNo, style: theme.textTheme.muted.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Only what was ordered. How much the warehouse has issued so far
          // is their business and the forklift operator's (it drives
          // smVendor's checklist and wps's "Wydano" line); the person who
          // placed this order needs "is it coming", which the status badge
          // and the ticked circle already answer.
          Text(required, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  String pad(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${pad(local.month)}-${pad(local.day)} ${pad(local.hour)}:${pad(local.minute)}';
}
