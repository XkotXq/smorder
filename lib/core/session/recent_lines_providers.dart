import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _recentLinesKey = 'smorder.recentLines';
const _maxRecent = 3;

/// The production lines this device ordered for most recently, newest first.
///
/// A foreman orders for **their own line**, over and over - so the single
/// most consequential field on the form is also the most predictable one.
/// Offering the last few as one-tap chips is what turns "open a dropdown,
/// scroll 24 codes, pick" into one tap, which matters when the phone is
/// being held in a glove next to a running line.
///
/// Per device, not per person (same reasoning as the locale/theme
/// providers): the phone belongs to a shift, and the shift works one area.
class RecentLinesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentLinesKey) ?? const [];
  }

  /// Called once an order is actually placed - a line somebody typed but
  /// abandoned is not a line they order for.
  Future<void> remember(String line) async {
    final value = line.trim();
    if (value.isEmpty) return;
    final current = state.value ?? const <String>[];
    final next = [value, ...current.where((l) => l != value)].take(_maxRecent).toList();
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentLinesKey, next);
  }
}

final recentLinesProvider = AsyncNotifierProvider<RecentLinesNotifier, List<String>>(RecentLinesNotifier.new);
