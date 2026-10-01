import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// wpsApi's own address - same LAN address the rest of this app family
/// (wps, smpda, smVendor) already points at during development. See
/// ../../../smVendor/lib/core/api/api_client.dart's own comment.
const _apiBaseUrl = 'http://10.96.12.204:4000/api';

/// Plain, unauthenticated Dio instance - only /auth/login needs this (see
/// wpsApi's AGENTS.md: unlike every other route, login doesn't need the
/// shared bearer apiToken).
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: _apiBaseUrl, connectTimeout: const Duration(seconds: 15)));
});

/// Every other wpsApi route needs the shared bearer token - same one
/// wps's/smVendor's own clients send. Read from a compile-time define
/// (`--dart-define=API_TOKEN=...`) rather than hardcoded, same reasoning as
/// ../../../smVendor's own authedDioProvider (this repo is public on GitHub).
const _apiToken = String.fromEnvironment('API_TOKEN');

final authedDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: _apiBaseUrl, connectTimeout: const Duration(seconds: 15)));
  if (_apiToken.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer $_apiToken';
  }
  return dio;
});
