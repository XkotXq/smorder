import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/session/locale_providers.dart';
import '../../core/session/session_providers.dart';
import '../../core/session/theme_providers.dart';
import '../../i18n/gen/strings.g.dart';

/// "Konto" - who's signed in and the way out, plus the PL/EN switch and the
/// theme picker. Same placement/shape as ../../../smVendor's own
/// AccountPage, minus its "Oznaczenie wózka" - that's a per-forklift
/// setting, not relevant here.
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final t = context.t.account;
    final session = ref.watch(sessionProvider).value;
    final locale = ref.watch(localeProvider).value ?? AppLocale.pl;
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session != null) ...[
              Text(session.name, style: theme.textTheme.h4, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(session.userId, style: theme.textTheme.muted, textAlign: TextAlign.center),
              const SizedBox(height: 32),
            ],
            Text(t.language, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Pill(
                  label: t.languagePolish,
                  selected: locale == AppLocale.pl,
                  onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocale.pl),
                ),
                const SizedBox(width: 12),
                _Pill(
                  label: t.languageEnglish,
                  selected: locale == AppLocale.en,
                  onTap: () => ref.read(localeProvider.notifier).setLocale(AppLocale.en),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(t.theme, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Pill(
                  label: t.themeSystem,
                  selected: themeMode == ThemeMode.system,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                ),
                const SizedBox(width: 12),
                _Pill(
                  label: t.themeLight,
                  selected: themeMode == ThemeMode.light,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                ),
                const SizedBox(width: 12),
                _Pill(
                  label: t.themeDark,
                  selected: themeMode == ThemeMode.dark,
                  onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ShadButton.outline(
                onPressed: () => ref.read(sessionProvider.notifier).logout(),
                child: Text(t.logout, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One option pill - filled when it's the active choice, same active/
/// inactive colour split as widgets/app_shell.dart's own nav rows. Used for
/// both the PL/EN switch and the theme picker above.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
