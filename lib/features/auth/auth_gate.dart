import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/session/session_providers.dart';
import '../../widgets/app_shell.dart';
import 'login_screen.dart';

/// Decides what the app opens on: the saved session's own order list, or
/// the login screen when there isn't one. The session is persisted (see
/// core/session/session_providers.dart), so this is also what keeps a
/// restart from asking for the password again.
///
/// Both screens are swapped here rather than pushed - LoginScreen only sets
/// the session and this rebuilds, and AccountPage's logout only clears it,
/// so neither needs to know about the other (and logging out can't leave a
/// stale shell underneath on the navigator stack).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final theme = ShadTheme.of(context);

    // Reading SharedPreferences takes a frame or two on a cold start -
    // show the app's own background rather than flashing the login screen
    // at someone who is in fact still logged in.
    if (session.isLoading) {
      return ColoredBox(color: theme.colorScheme.background, child: const SizedBox.expand());
    }
    return session.value == null ? const LoginScreen() : const AppShell();
  }
}
