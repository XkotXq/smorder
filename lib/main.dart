import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/session/locale_providers.dart';
import 'core/session/theme_providers.dart';
import 'features/auth/auth_gate.dart';
import 'i18n/gen/strings.g.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(TranslationProvider(child: const ProviderScope(child: SmOrderApp())));
}

/// Root widget - the requester's (brygadzista's) own "apka do zamawiania":
/// places transport orders (see features/orders/) and watches them through
/// to done/cancelled. Same shadcn/navy design and app-family shape as
/// ../../smVendor's own SmVendorApp (mirrored from there) - no router yet;
/// features/auth/auth_gate.dart swaps login/shell off the persisted
/// session instead.
class SmOrderApp extends ConsumerWidget {
  const SmOrderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).value ?? AppLocale.pl;
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    if (LocaleSettings.currentLocale != locale) {
      LocaleSettings.setLocale(locale);
    }
    return ShadApp(
      title: 'smOrder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale.flutterLocale,
      supportedLocales: AppLocale.values.map((l) => l.flutterLocale),
      home: const AuthGate(),
    );
  }
}
