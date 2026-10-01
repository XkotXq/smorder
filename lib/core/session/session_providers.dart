import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_api.dart';

const _sessionKey = 'smorder.session';

/// Who's logged in right now, **persisted across restarts** - reopening the
/// app (or reloading the web build) lands straight on the order list
/// instead of the login screen. Same SharedPreferences-backed shape as
/// locale_providers.dart/theme_providers.dart; ../../../smVendor's own
/// SessionNotifier is still in-memory only by comparison.
///
/// A restored session is never expired out here: nothing in this app
/// authorizes with the CIP token (see AuthSession.token's own comment - the
/// shared API_TOKEN does that), so there is no request that could start
/// failing because the stored token aged. Logging out is explicit, via
/// AccountPage.
class SessionNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Unreadable leftovers (an older shape, a half-written value) are
      // treated as "not logged in" rather than crashing the app on launch.
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  Future<void> setSession(AuthSession session) async {
    state = AsyncData(session);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  /// A CIP token good to send to CIP right now, renewing it first when the
  /// stored one has aged past its expiry (see AuthApi.refresh). Only the CIP
  /// material lookup needs this - everything else here authorizes with the
  /// shared API_TOKEN. Returns null when there is no session, or when even
  /// the refresh token is dead; the caller then tells the person to log in
  /// again rather than silently doing nothing.
  Future<String?> freshCipToken(AuthApi Function() authApi) async {
    final current = state.value;
    if (current == null) return null;
    final expired = current.expiresAt > 0 && DateTime.now().millisecondsSinceEpoch > current.expiresAt - 60000;
    if (!expired) return current.token;
    try {
      final renewed = await authApi().refresh(current);
      await setSession(renewed);
      return renewed.token;
    } catch (_) {
      return null;
    }
  }

  /// Marks the stored CIP token as dead, so the next [freshCipToken] tries a
  /// refresh instead of handing out a token CIP has already rejected. Keeps
  /// the person logged in - their identity is still what this app needs.
  Future<void> invalidateCipToken() async {
    final current = state.value;
    if (current == null) return;
    await setSession(
      AuthSession(
        token: current.token,
        name: current.name,
        userId: current.userId,
        refreshToken: current.refreshToken,
        expiresAt: 1,
      ),
    );
  }

  Future<void> logout() async {
    state = const AsyncData(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, AuthSession?>(SessionNotifier.new);
