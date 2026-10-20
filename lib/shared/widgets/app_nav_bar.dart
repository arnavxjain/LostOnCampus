import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/shapes.dart';

class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.symbol,
    required this.icon,
    this.selectedSymbol,
    this.selectedIcon,
    this.badge = 0,
  });

  final String label;

  /// SF Symbol names for the native iOS bar.
  final String symbol;
  final String? selectedSymbol;

  /// Material icons for the fallback bar.
  final IconData icon;
  final IconData? selectedIcon;

  /// Unread count; 0 hides the badge.
  final int badge;
}

/// Native iOS Liquid Glass tab bar, with a matching Flutter pill bar on Android
/// and iOS versions without Liquid Glass.
class AppNavBar extends StatelessWidget {
  /// Set once at startup by [checkGlassSupport]. Deciding up front avoids the
  /// fallback bar flashing on iOS while the native support check runs.
  static bool _glassSupported = false;

  /// Extra space between the bar and the bottom of the screen, on top of the
  /// safe area. Shared by students and admins.
  static const bottomGap = 16.0;

  /// The native bar's size relative to the standard iOS tab bar.
  static const nativeScale = 0.9;

  static Future<void> checkGlassSupport() async {
    _glassSupported = await LiquidGlassHelper.isLiquidGlassSupported();
  }

  const AppNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.onAction,
    this.actionSymbol = 'plus',
    this.actionIcon = CupertinoIcons.plus,
    this.actionLabel = 'Add',
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Optional round action button next to the tabs.
  final VoidCallback? onAction;
  final String actionSymbol;
  final IconData actionIcon;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    if (!_glassSupported) return _PillNavBar(bar: this);
    return Padding(
      padding: const EdgeInsets.only(bottom: bottomGap),
      child: Transform.scale(
        scale: nativeScale,
        alignment: Alignment.bottomCenter,
        child: NativeGlassNavBar(
          currentIndex: currentIndex,
          onTap: onTap,
          tintColor: AppColors.teal,
          actionButton: onAction == null ? null : TabBarActionButton(symbol: actionSymbol, onTap: onAction!),
          tabs: [
            for (final item in items)
              NativeGlassNavBarItem(
                label: item.label,
                symbol: item.symbol,
                selectedSymbol: item.selectedSymbol,
                badgeValue: item.badge > 0 ? '${item.badge}' : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _PillNavBar extends StatelessWidget {
  const _PillNavBar({required this.bar});

  final AppNavBar bar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const shadow = [BoxShadow(color: AppColors.ink6, blurRadius: 24, offset: Offset(0, 8))];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12 + AppNavBar.bottomGap),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: ShapeDecoration(
              color: AppColors.background,
              shape: AppShapes.pill(side: const BorderSide(color: AppColors.teal32)),
              shadows: shadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < bar.items.length; i++)
                  _PillTab(
                    item: bar.items[i],
                    selected: i == bar.currentIndex,
                    onTap: () => bar.onTap(i),
                    textTheme: textTheme,
                  ),
              ],
            ),
          ),
          if (bar.onAction != null) ...[
            const SizedBox(width: 10),
            Material(
              color: AppColors.teal,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: bar.onAction,
                child: SizedBox.square(
                  dimension: 50,
                  child: Icon(bar.actionIcon, color: AppColors.background, semanticLabel: bar.actionLabel),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({required this.item, required this.selected, required this.onTap, required this.textTheme});

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.teal : AppColors.ink;
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        customBorder: AppShapes.pill(),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: ShapeDecoration(color: selected ? AppColors.teal13 : Colors.transparent, shape: AppShapes.pill()),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: item.badge > 0,
                label: Text('${item.badge}'),
                backgroundColor: AppColors.accent,
                textColor: AppColors.ink,
                child: Icon(selected ? (item.selectedIcon ?? item.icon) : item.icon, color: color, size: 22),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
