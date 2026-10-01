import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../features/account/account_page.dart';
import '../features/orders/orders_page.dart';
import '../i18n/gen/strings.g.dart';

class _NavEntry {
  const _NavEntry(this.icon, this.label, this.page);
  final IconData icon;
  final String label;
  final Widget page;
}

/// The whole app past login - same "plain widget state, not a route" shell
/// as ../../../smVendor's own AppShell (see that file's own comment on why
/// there's no router yet). Unlike smVendor's/smpda's own shell, this one is
/// phone-first - smOrder is mainly used on a phone, so there's no side-nav
/// variant for a wide screen here, just the bottom tab bar, always.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selected = 0;

  void _select(int index) => setState(() => _selected = index);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.nav;
    final items = [
      _NavEntry(LucideIcons.clipboardList, t.ordering, const OrdersPage()),
      _NavEntry(LucideIcons.user, t.account, const AccountPage()),
    ];

    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Column(
          children: [
            _Header(title: items[_selected].label),
            Expanded(child: items[_selected].page),
            _BottomNav(items: items, selected: _selected, onSelect: _select),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.h2.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom tab bar - same shape as ../../../smVendor's own _BottomNav
/// (phone case), just the only nav this app ever shows.
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.items, required this.selected, required this.onSelect});
  final List<_NavEntry> items;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.border))),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            _BottomNavButton(entry: items[i], active: i == selected, onTap: () => onSelect(i)),
        ],
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({required this.entry, required this.active, required this.onTap});
  final _NavEntry entry;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = active ? theme.colorScheme.primary : theme.colorScheme.mutedForeground;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(entry.icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(entry.label, style: theme.textTheme.small.copyWith(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
