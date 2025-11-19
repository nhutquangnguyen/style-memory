import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// A modern, consistent card component with enhanced styling options
class ModernCard extends StatelessWidget {
  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation = AppTheme.elevationLow,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.onTap,
    this.shadow,
    this.gradient,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final BoxShadow? shadow;
  final Gradient? gradient;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = BorderRadius.circular(AppTheme.borderRadiusLarge);
    final effectiveBorderRadius = borderRadius ?? defaultBorderRadius;

    Widget cardChild = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? AppTheme.cardColor) : null,
        gradient: gradient,
        borderRadius: effectiveBorderRadius,
        border: borderWidth > 0
          ? Border.all(
              color: borderColor ?? AppTheme.borderColor,
              width: borderWidth,
            )
          : null,
        boxShadow: elevation > 0
          ? [shadow ?? AppTheme.cardShadow]
          : null,
      ),
      child: child,
    );

    if (onTap != null) {
      cardChild = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          highlightColor: AppTheme.primaryColor.withValues(alpha: 0.05),
          child: cardChild,
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardChild,
    );
  }
}

/// A specialized card for displaying content with a header
class ModernHeaderCard extends StatelessWidget {
  const ModernHeaderCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    this.headerPadding,
    this.contentPadding,
    this.margin,
    this.elevation = AppTheme.elevationLow,
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry? headerPadding;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      margin: margin,
      elevation: elevation,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            padding: headerPadding ?? const EdgeInsets.fromLTRB(
              AppTheme.spacingMedium,
              AppTheme.spacingMedium,
              AppTheme.spacingMedium,
              AppTheme.spacingSmall,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppTheme.spacingSmall),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppTheme.spacingSmall),
                  trailing!,
                ],
              ],
            ),
          ),
          // Content section
          Container(
            padding: contentPadding ?? const EdgeInsets.fromLTRB(
              AppTheme.spacingMedium,
              0,
              AppTheme.spacingMedium,
              AppTheme.spacingMedium,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A card specifically designed for statistics or metrics
class ModernStatCard extends StatelessWidget {
  const ModernStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.trend,
    this.trendPositive,
    this.color,
    this.onTap,
    this.margin,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final String? trend;
  final bool? trendPositive;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? AppTheme.primaryColor;

    return ModernCard(
      margin: margin,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: Icon(
                    icon,
                    color: effectiveColor,
                    size: AppTheme.iconLg,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trend != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: (trendPositive == true
                      ? AppTheme.successColor
                      : AppTheme.errorColor).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusXs),
                  ),
                  child: Text(
                    trend!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: trendPositive == true
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: effectiveColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}