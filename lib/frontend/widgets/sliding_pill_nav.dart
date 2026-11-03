import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/config/app_frost.dart';
import '../../core/config/app_liquid_glass.dart';
import '../../core/config/app_nav_pill_style.dart';
import '../../core/config/app_pill_gradient.dart';
import '../../core/config/app_visual_style.dart';
import 'animated_lottie_icon.dart';
import 'glossy_pill.dart';
import 'liquid_glass.dart';

class PillNavItem {
  final IconData icon;
  final String label;
  final bool longPressable;
  final String? animationAsset;

  const PillNavItem({
    required this.icon,
    required this.label,
    this.longPressable = false,
    this.animationAsset,
  });
}

class PillNavGeometry {
  final double navInnerW;
  final double activeWidth;
  final double inactiveWidth;

  const PillNavGeometry(this.navInnerW, this.activeWidth, this.inactiveWidth);

  factory PillNavGeometry.fromInnerWidth(double navInnerW, int itemCount) {
    final totalWeight = (itemCount - 1) + _activeWeight;
    final unit = navInnerW / totalWeight;
    return PillNavGeometry(navInnerW, unit * _activeWeight, unit);
  }

  factory PillNavGeometry.equal(double itemWidth, int itemCount) =>
      PillNavGeometry(itemWidth * itemCount, itemWidth, itemWidth);

  static const double _activeWeight = 2.2;
}

class SlidingPillNav extends StatelessWidget {
  final List<PillNavItem> items;
  final double position;
  final Duration animationDuration;
  final PillNavGeometry geometry;
  final ValueChanged<int> onTap;
  final void Function(int index, Offset globalPosition)? onItemLongPress;
  final double iconSize;
  final double labelGap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool iconsOnly;
  final BackdropKey? backdropKey;

  const SlidingPillNav({
    super.key,
    required this.items,
    required this.position,
    required this.geometry,
    required this.onTap,
    this.animationDuration = Duration.zero,
    this.onItemLongPress,
    this.iconSize = 22,
    this.labelGap = 6,
    this.backgroundColor,
    this.borderColor,
    this.iconsOnly = false,
    this.backdropKey,
  });

  static const double height = 68;

  double _interpWidth(int tab) {
    final maxIndex = items.length - 1;
    final rt = position.clamp(0.0, maxIndex.toDouble());
    final i0 = rt.floor();
    final i1 = rt.ceil();
    final frac = i0 == i1 ? 0.0 : rt - i0;
    double at(int sel) =>
        (tab == sel ? geometry.activeWidth : geometry.inactiveWidth) - 0.5;
    return at(i0) + (at(i1) - at(i0)) * frac;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VisualStyle>(
      valueListenable: AppVisualStyle.current,
      builder: (context, style, _) {
        if (style == VisualStyle.materialYou) {
          return _buildNav(
            context,
            glossy: false,
            gradient: false,
            frost: false,
            liquid: false,
          );
        }
        return ValueListenableBuilder<bool>(
          valueListenable: AppPillGradient.current,
          builder: (context, gradient, _) =>
              ValueListenableBuilder<NavPillStyle>(
                valueListenable: AppNavPillStyle.current,
                builder: (context, navStyle, _) => _buildNav(
                  context,
                  glossy: true,
                  gradient: gradient,
                  frost: NavPillMaterial.isFrost(navStyle),
                  liquid: NavPillMaterial.isLiquid(navStyle),
                ),
              ),
        );
      },
    );
  }

  Widget _buildNav(
    BuildContext context, {
    required bool glossy,
    required bool gradient,
    required bool frost,
    required bool liquid,
  }) {
    final cs = Theme.of(context).colorScheme;
    final visualSel = position.round().clamp(0, items.length - 1);
    final translucent = backgroundColor != null && backgroundColor!.a < 1;
    final base = liquid
        ? (translucent ? backgroundColor! : AppLiquidGlass.navTint(cs))
        : (backgroundColor ??
              (frost ? AppFrost.glassTint(cs) : cs.surfaceContainerHigh));
    final useGradient = glossy && gradient && !liquid;
    final frosted = frost && !liquid && base.a < 1;
    final cellWidth = geometry.navInnerW / items.length;
    final rimColor = Colors.white.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.55,
    );

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: useGradient || liquid ? null : base,
        gradient: useGradient ? GlossyDecor.fillGradient(base) : null,
        borderRadius: BorderRadius.circular(34),
        border: liquid
            ? Border.all(color: rimColor, width: 0.8)
            : glossy
            ? GlossyDecor.rimBorder(base)
            : (borderColor != null
                  ? Border.all(color: borderColor!, width: 0.5)
                  : null),
        boxShadow: frosted
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: liquid ? 0.12 : 0.5),
                  blurRadius: liquid ? 28 : 20,
                  offset: Offset(0, liquid ? 8 : 10),
                ),
              ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (liquid)
            Positioned.fill(
              child: IgnorePointer(
                child: LiquidGlassSurface(
                  borderRadius: BorderRadius.circular(34),
                  tint: base,
                  blurSigma: 5,
                  refraction: 22,
                  rimWidth: 10,
                ),
              ),
            ),
          if (frosted)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: AppFrost.sigma,
                      sigmaY: AppFrost.sigma,
                    ),
                    backdropGroupKey: backdropKey,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          if (useGradient)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(34),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: GlossyDecor.topSheen(base),
                    ),
                  ),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: animationDuration,
            curve: Curves.easeOutCubic,
            left: liquid
                ? position * cellWidth + 4
                : position * geometry.inactiveWidth + 4,
            top: liquid ? 5 : 8,
            bottom: liquid ? 5 : 8,
            width: liquid ? cellWidth - 8 : geometry.activeWidth - 8,
            child: liquid
                ? IgnorePointer(child: _LiquidNavIndicator(cs: cs))
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
          ),
          SizedBox(
            width: geometry.navInnerW,
            child: Row(
              children: List.generate(items.length, (i) {
                return AnimatedContainer(
                  duration: animationDuration,
                  curve: Curves.easeOutCubic,
                  width: liquid ? cellWidth : _interpWidth(i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: _PillNavCell(
                      item: items[i],
                      selected: i == visualSel,
                      cs: cs,
                      animationDuration: animationDuration,
                      iconSize: iconSize,
                      labelGap: labelGap,
                      iconsOnly: iconsOnly,
                      stacked: liquid,
                      onTap: () => onTap(i),
                      onLongPress:
                          (onItemLongPress == null || !items[i].longPressable)
                          ? null
                          : (pos) => onItemLongPress!(i, pos),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillNavCell extends StatelessWidget {
  final PillNavItem item;
  final bool selected;
  final ColorScheme cs;
  final Duration animationDuration;
  final double iconSize;
  final double labelGap;
  final bool iconsOnly;
  final bool stacked;
  final VoidCallback onTap;
  final void Function(Offset globalPosition)? onLongPress;

  const _PillNavCell({
    required this.item,
    required this.selected,
    required this.cs,
    required this.animationDuration,
    required this.iconSize,
    required this.labelGap,
    required this.iconsOnly,
    required this.stacked,
    required this.onTap,
    required this.onLongPress,
  });

  Widget _buildIcon() {
    final color = stacked
        ? (selected ? cs.primary : cs.onSurface.withValues(alpha: 0.78))
        : (selected ? cs.onPrimary : cs.onSurface);
    final asset = item.animationAsset;
    if (asset != null) {
      return AnimatedLottieIcon(
        asset: asset,
        color: color,
        size: iconSize,
        active: selected,
      );
    }
    return Icon(item.icon, color: color, size: iconSize, fill: 1);
  }

  @override
  Widget build(BuildContext context) {
    final opacityDuration = animationDuration == Duration.zero
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onLongPress == null
          ? null
          : (d) => onLongPress!(d.globalPosition),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: stacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIcon(),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: selected
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : iconsOnly
            ? _buildIcon()
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcon(),
                    AnimatedContainer(
                      duration: animationDuration,
                      curve: Curves.easeOutCubic,
                      width: selected ? null : 0,
                      child: AnimatedOpacity(
                        duration: opacityDuration,
                        opacity: selected ? 1.0 : 0.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: labelGap),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _LiquidNavIndicator extends StatelessWidget {
  final ColorScheme cs;

  const _LiquidNavIndicator({required this.cs});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      borderRadius: BorderRadius.circular(30),
      tint: cs.primary.withValues(alpha: 0.16),
      blurSigma: 0,
      refraction: 14,
      specular: 0.7,
      rimWidth: 6,
      tintFeather: 22,
    );
  }
}
