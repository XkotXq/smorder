import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Result of a successful CIP login - mirrors wpsApi's own
/// POST /api/auth/login response shape (src/routes/auth.js), same as
/// ../../../smVendor's own AuthApi.
///
/// Persisted across restarts (see core/session/session_providers.dart) so
/// nobody has to log in again every time the app is reopened - hence the
/// toJson/fromJson below.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.name,
    required this.userId,
    this.refreshToken = '',
    this.expiresAt = 0,
  });

  /// CIP's own access token. Kept for completeness only - **nothing in this
  /// app authorizes with it**: every wpsApi call goes out with the shared
  /// API_TOKEN instead (see api_client.dart), and the employee number
  /// attached to an order is asserted by the client (see wpsApi's AGENTS.md,
  /// "Auth"). That's why a restored session is never rejected over an
  /// expired token here. If something in this app ever does start sending
  /// this token to CIP, don't trust this stored copy - renew it the way
  /// ../../../smpda's own CipSessionService does.
  final String token;

  /// Display name (wpsApi's `name` - CIP's own `user_info.employee`,
  /// falling back to whatever username was typed).
  final String name;

  /// CIP username (wpsApi's `userId`) - the employee number, sent as this
  /// app's own `employeeNo` on every order it places (requested_by).
  final String userId;

  /// For the OAuth2 refresh grant (wpsApi's POST /auth/refresh) - unused so
  /// far, see [token].
  final String refreshToken;

  /// When [token] stops being valid (epoch milliseconds), from the login
  /// answer's `expiresIn`. 0 when the server didn't say.
  final int expiresAt;

  Map<String, dynamic> toJson() => {
    'token': token,
    'name': name,
    'userId': userId,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt,
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: json['token'] as String? ?? '',
    name: json['name'] as String? ?? '',
    userId: json['userId'] as String? ?? '',
    refreshToken: json['refreshToken'] as String? ?? '',
    expiresAt: json['expiresAt'] as int? ?? 0,
  );
}

/// A failed login. [code] is wpsApi's stable error code (invalid_credentials,
/// cip_unreachable, too_many_attempts, ...) - LoginScreen turns it into a
/// message in Polish, since CIP's own text is Chinese. Null when the server
/// couldn't be reached at all.
class AuthFailure implements Exception {
  AuthFailure(this.code, this.message);
  final String? code;

  /// wpsApi's Polish fallback message, for a code this app doesn't know.
  final String message;

  @override
  String toString() => message;
}

/// POST /api/auth/login - proxies the company's legacy CIP system's OAuth2
/// password grant (see wpsApi's src/routes/auth.js). Doesn't need the
/// shared bearer apiToken, unlike every other wpsApi route. No deviceLabel
/// param (unlike smVendor's own) - that's a per-forklift setting, not
/// relevant to whoever is placing orders from this app.
class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  /// Throws an [AuthFailure] - LoginScreen shows its `code` in Polish
  /// rather than the server's own text.
  Future<AuthSession> login(String username, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final data = res.data!;
      final expiresIn = data['expiresIn'];
      return AuthSession(
        token: data['token'] as String,
        name: data['name'] as String? ?? username,
        userId: data['userId'] as String? ?? username,
        refreshToken: data['refreshToken'] as String? ?? '',
        expiresAt: expiresIn is num ? DateTime.now().millisecondsSinceEpoch + expiresIn.toInt() * 1000 : 0,
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      final serverMessage = body is Map ? body['error'] as String? : null;
      final code = body is Map ? body['code'] as String? : null;
      throw AuthFailure(code, serverMessage ?? 'Nie udało się połączyć z serwerem.');
    }
  }

  /// POST /api/auth/refresh - the OAuth2 refresh grant (see wpsApi's
  /// routes/auth.js). Needed because the CIP material lookup
  /// (core/api/cip_orders_api.dart) really does send this token to CIP, so a
  /// stored session that aged past its expiry has to be renewable rather
  /// than just forcing a new login.
  Future<AuthSession> refresh(AuthSession current) async {
    if (current.refreshToken.isEmpty) throw AuthFailure('session_expired', 'Sesja wygasła - zaloguj się ponownie.');
    try {
      final res = await _dio.post<Map<String, dynamic>>('/auth/refresh', data: {'refreshToken': current.refreshToken});
      final data = res.data!;
      final expiresIn = data['expiresIn'];
      return AuthSession(
        token: data['token'] as String,
        // The refresh answer doesn't always repeat who this is - keep what
        // the session already knows rather than blanking the name.
        name: data['name'] as String? ?? current.name,
        userId: data['userId'] as String? ?? current.userId,
        refreshToken: data['refreshToken'] as String? ?? current.refreshToken,
        expiresAt: expiresIn is num ? DateTime.now().millisecondsSinceEpoch + expiresIn.toInt() * 1000 : 0,
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      final code = body is Map ? body['code'] as String? : null;
      throw AuthFailure(code ?? 'session_expired', 'Sesja wygasła - zaloguj się ponownie.');
    }
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));
