import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../i18n/gen/strings.g.dart';

const _localeKey = 'smorder.localeCode';

/// The chosen language (pl/en), persisted across restarts - same pattern as
/// ../../../smVendor's own LocaleNotifier. Defaults to Polish - slang.yaml's
/// own base_locale, this app family's primary language.
class LocaleNotifier extends AsyncNotifier<AppLocale> {
  @override
  Future<AppLocale> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) == 'en' ? AppLocale.en : AppLocale.pl;
  }

  Future<void> setLocale(AppLocale locale) async {
    state = AsyncData(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, AppLocale>(LocaleNotifier.new);
