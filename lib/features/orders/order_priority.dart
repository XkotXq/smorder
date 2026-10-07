import 'package:flutter/widgets.dart';
// LucideIcons comes through shadcn_ui, which re-exports it - the icon
// package is not a direct dependency of this app and should not become one
// (see AGENTS.md, "Don't add another UI package").
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../i18n/gen/strings.g.dart';
import '../../theme/app_colors.dart';

/// How urgent the requester says a transport is - wpsApi's own PRIORITIES,
/// least to most (see its schema.sql).
///
/// Three levels, deliberately: a scale people have to think about is a
/// scale everybody sets to the top. 'normal' is the default and is green,
/// because an ordinary transport is not an exception - a queue where every
/// card is amber tells the forklift operator nothing.
const orderPriorities = ['normal', 'urgent', 'critical'];

/// The same three rising bars at every level, in the level's own colour -
/// green, amber, red. One shape, so the icon is recognised before it is
/// read; colour alone carries the level, which is what was asked for.
const orderPriorityIcon = LucideIcons.chartNoAxesColumnIncreasing;

Color orderPriorityColor(String priority, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (priority) {
    // The app's own red, the one the destructive theme colour uses - not
    // a new one invented for this icon.
    'critical' => dark ? AppColors.destructiveDark : AppColors.destructiveLight,
    'urgent' => dark ? AppColors.yellow400 : AppColors.yellow600,
    _ => dark ? AppColors.green400 : AppColors.green600,
  };
}

String orderPriorityLabel(Translations t, String priority) => switch (priority) {
  'critical' => t.orders.priority.critical,
  'urgent' => t.orders.priority.urgent,
  _ => t.orders.priority.normal,
};
