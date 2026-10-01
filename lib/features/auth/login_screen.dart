import 'package:flutter/material.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/auth_api.dart';
import '../../core/session/session_providers.dart';
import '../../i18n/gen/strings.g.dart';

/// Shown by AuthGate when there's no saved session - same CIP login
/// wps/smpda/smVendor already use, proxied through wpsApi's
/// POST /api/auth/login (see AuthApi). Same big-touch-target design as
/// ../../../smVendor's own LoginScreen (copied from there, minus its
/// deviceLabel - that's a per-forklift setting, not relevant to whoever is
/// placing orders). A successful login is saved to the device, so this
/// screen is not seen again until someone logs out.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _showPassword = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty || _submitting) {
      if (username.isEmpty || password.isEmpty) setState(() => _error = context.t.login.missingFields);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = await ref.read(authApiProvider).login(username, password);
      if (!mounted) return;
      // Saved to the device here (see SessionNotifier) - AuthGate is
      // watching the session and swaps this screen for the app itself, so
      // there's nothing to navigate to by hand.
      await ref.read(sessionProvider.notifier).setSession(session);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _messageFor(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(Object error) {
    final errors = context.t.login.errors;
    if (error is AuthFailure) {
      return switch (error.code) {
        'invalid_credentials' => errors.invalidCredentials,
        'cip_unreachable' => errors.cipUnreachable,
        'too_many_attempts' => errors.tooManyAttempts,
        null => errors.serverUnreachable,
        _ => error.message,
      };
    }
    return errors.serverUnreachable;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t.login;
    final fieldStyle = theme.textTheme.p.copyWith(fontSize: 18);

    Widget bigField({
      required String label,
      required TextEditingController controller,
      required FocusNode focusNode,
      required FocusNode? nextFocus,
      bool obscure = false,
      Widget? trailing,
      TextInputAction action = TextInputAction.next,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ShadInput(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            style: fieldStyle,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            trailing: trailing,
            textInputAction: action,
            onSubmitted: (_) {
              if (nextFocus != null) {
                nextFocus.requestFocus();
              } else {
                _submit();
              }
            },
          ),
        ],
      );
    }

    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'SO',
                      style: theme.textTheme.h2.copyWith(color: theme.colorScheme.primaryForeground, fontSize: 26),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(t.title, style: theme.textTheme.h2, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    t.subtitle,
                    style: theme.textTheme.muted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: theme.colorScheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        bigField(
                          label: t.usernameLabel,
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          nextFocus: _passwordFocus,
                        ),
                        const SizedBox(height: 20),
                        bigField(
                          label: t.passwordLabel,
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          nextFocus: null,
                          obscure: !_showPassword,
                          action: TextInputAction.done,
                          trailing: ExcludeFocus(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _showPassword = !_showPassword),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.destructive.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _error!,
                              style: theme.textTheme.small.copyWith(color: theme.colorScheme.destructive),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 60,
                          child: ShadButton(
                            onPressed: _submitting ? null : _submit,
                            child: Text(
                              _submitting ? t.submitting : t.submit,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
