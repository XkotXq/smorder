import 'dart:async';

import 'package:flutter/material.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/session/session_providers.dart';
import '../../i18n/gen/strings.g.dart';
import 'orders_api.dart';

/// How often the thread asks for anything newer. One second, because a chat
/// that lags feels broken - and it costs almost nothing: the request carries
/// the last id held, so the answer is an empty array every time but the one
/// where somebody has just written something (measured at ~6 ms a call
/// against the dev API).
///
/// A socket would be instant rather than within-a-second, at the price of a
/// new dependency, reconnect handling and a stream through the LAN tunnel.
/// Polling is what every other live screen in this app family already does
/// (see AGENTS.md), and at this interval the difference is not something a
/// person typing can feel.
const _pollInterval = Duration(seconds: 1);

/// The chat on one transport order - reached from the "Czat" button beside
/// "Problem rozwiązany", which is where it is actually needed: a problem one
/// side reported and the other has to act on.
///
/// Both apps open the same thread (wpsApi's order_messages), so the forklift
/// operator and the person who ordered the transport are talking to each
/// other, not into two separate boxes.
class OrderChatPage extends ConsumerStatefulWidget {
  const OrderChatPage({super.key, required this.orderId, required this.orderNo});

  final String orderId;
  final String orderNo;

  @override
  ConsumerState<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends ConsumerState<OrderChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<OrderMessage> _messages = [];
  Timer? _pollTimer;
  bool _polling = false;
  bool _loading = true;
  bool _failed = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final all = await ref.read(ordersApiProvider).messages(widget.orderId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(all);
        _loading = false;
      });
      _scrollToEnd();
      _markRead();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// Records how far this person has read, so the badge on the order clears.
  /// Deliberately not awaited and silent on failure: it is bookkeeping, and
  /// a lost call only leaves the badge up until the thread is opened again.
  void _markRead() {
    final last = _messages.isEmpty ? null : _messages.last.id;
    if (last == null) return;
    ref
        .read(ordersApiProvider)
        .markRead(widget.orderId, employeeNo: ref.read(sessionProvider).value?.userId ?? '', lastReadId: last)
        .catchError((_) {});
  }

  /// Asks only for what is newer than the last message held, and appends it.
  /// Silent on failure: a dropped poll on warehouse Wi-Fi costs one second,
  /// and blanking a thread somebody is reading would be worse than a gap.
  Future<void> _poll() async {
    if (_polling || _loading) return;
    _polling = true;
    try {
      final fresh = await ref
          .read(ordersApiProvider)
          .messages(widget.orderId, afterId: _messages.isEmpty ? null : _messages.last.id);
      if (!mounted || fresh.isEmpty) return;
      final atEnd = _isNearEnd();
      setState(() => _messages.addAll(fresh.where((m) => !_messages.any((x) => x.id == m.id))));
      // Read as it arrives - the thread is open and on screen.
      _markRead();
      // Only follow the thread down if the reader was already at the bottom -
      // yanking the view while somebody scrolls back through it is rude.
      if (atEnd) _scrollToEnd();
    } catch (_) {
      // Left to the next tick.
    } finally {
      _polling = false;
    }
  }

  bool _isNearEnd() {
    if (!_scrollController.hasClients) return true;
    final p = _scrollController.position;
    return p.pixels >= p.maxScrollExtent - 80;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = await ref.read(ordersApiProvider).sendMessage(
        widget.orderId,
        author: ref.read(sessionProvider).value?.userId ?? '',
        body: text,
      );
      if (!mounted) return;
      setState(() {
        if (!_messages.any((m) => m.id == sent.id)) _messages.add(sent);
        _controller.clear();
        _sending = false;
      });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final message = e is OrderActionFailure ? e.message : context.t.orders.chat.sendError;
      ShadToaster.of(context).show(ShadToast.destructive(description: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.orders.chat;
    final me = ref.read(sessionProvider).value?.userId ?? '';

    Widget body;
    if (_loading) {
      body = Center(child: Text(context.t.orders.loading, style: theme.textTheme.muted));
    } else if (_failed && _messages.isEmpty) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.loadError, style: theme.textTheme.muted.copyWith(color: theme.colorScheme.destructive)),
            const SizedBox(height: 12),
            ShadButton.outline(onPressed: _load, child: Text(context.t.orders.retry)),
          ],
        ),
      );
    } else if (_messages.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(t.empty, style: theme.textTheme.muted, textAlign: TextAlign.center),
        ),
      );
    } else {
      body = ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemCount: _messages.length,
        itemBuilder: (context, i) => _Bubble(message: _messages[i], mine: _messages[i].author == me),
      );
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
                  ShadButton.ghost(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(LucideIcons.arrowLeft),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title, style: theme.textTheme.h3.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(widget.orderNo, style: theme.textTheme.muted.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                border: Border(top: BorderSide(color: theme.colorScheme.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ShadInput(
                      controller: _controller,
                      placeholder: Text(t.placeholder),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ShadButton(
                      onPressed: _sending ? null : _send,
                      child: const Icon(LucideIcons.send, size: 18),
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
}

/// One message. A ShadCard rather than a hand-rolled box: shadcn_ui has no
/// message/chat component of its own (checked in 0.57), and the card is the
/// surface primitive it does give - so the bubble carries the same radius,
/// border and shadow as every other surface in the app.
///
/// Own messages sit right and take the accent background; the other side
/// sits left on the card background. The author is only labelled on their
/// messages - repeating "Ty" over every one of your own is noise.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final OrderMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
            child: ShadCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: mine ? theme.colorScheme.accent : theme.colorScheme.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!mine) ...[
                    Text(
                      message.author,
                      style: theme.textTheme.small.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(message.body, style: theme.textTheme.p),
                  const SizedBox(height: 2),
                  Text(_time(message.at), style: theme.textTheme.muted.copyWith(fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final local = value.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(local.hour)}:${pad(local.minute)}';
  }
}
