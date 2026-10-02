import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
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
      home: const _AboveKeyboard(child: _SystemBars(child: AuthGate())),
    );
  }
}

/// Makes the Android status bar and navigation bar usable on both themes:
/// their icons and the clock are drawn by the system in whatever contrast
/// the app asks for, and an app that asks for nothing gets light icons -
/// invisible on this app's light background.
///
/// Reads the **resolved** brightness from ShadTheme rather than the chosen
/// ThemeMode, so "system" lands on the right one, and sits inside ShadApp so
/// it covers every route pushed later (the shell, every order page).
/// AnnotatedRegion rather than SystemChrome.setSystemUIOverlayStyle: it
/// follows the widget tree instead of being a one-off side effect that a
/// later route or a theme switch could leave stale.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = ShadTheme.of(context).brightness == Brightness.dark;
    final icons = dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0x00000000),
        statusBarIconBrightness: icons,
        // iOS words it the other way round - this is the brightness of the
        // bar, not of what is drawn on it.
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: ShadTheme.of(context).colorScheme.background,
        systemNavigationBarIconBrightness: icons,
      ),
      child: child,
    );
  }
}

/// Shrinks the app to the space above the on-screen keyboard instead of
/// letting the keyboard cover it.
///
/// Android is already told to resize for the keyboard
/// (`windowSoftInputMode="adjustResize"` in AndroidManifest.xml), but that
/// only makes it *report* the inset: Flutter keeps the window its full size
/// and raises `MediaQuery.viewInsets.bottom`. Material's Scaffold is what
/// normally turns that into padding - and these apps have no Scaffold
/// (shadcn_ui on package:flutter/widgets.dart), so without this the
/// keyboard simply sat on top of the layout, hiding whatever was at the
/// bottom: the send button in the chat, "Dostarczone", the problem footer.
///
/// Sits inside ShadApp, so it covers every route pushed later as well.
/// `removeViewInsets` strips the inset for everything below, or widgets that
/// handle it themselves (a scrolling field, a SafeArea) would count it a
/// second time and leave a gap the height of the keyboard.
class _AboveKeyboard extends StatelessWidget {
  const _AboveKeyboard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: child,
      ),
    );
  }
}
