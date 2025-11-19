import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Enumeration for badge variants
enum ModernBadgeVariant {
  primary,
  secondary,
  success,
  warning,
  error,
  info,
  neutral,
}

/// Enumeration for badge sizes
enum ModernBadgeSize {
  small,
  medium,
  large,
}

/// A modern, consistent badge component for status indicators
class ModernBadge extends StatelessWidget {
  const ModernBadge({
    super.key,
    required this.text,
    this.variant = ModernBadgeVariant.primary,
    this.size = ModernBadgeSize.medium,
    this.icon,
    this.onTap,
    this.outlined = false,
  });

  final String text;
  final ModernBadgeVariant variant;
  final ModernBadgeSize size;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final colorConfig = _getColorConfig();
    final sizeConfig = _getSizeConfig();

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: sizeConfig.iconSize,
            color: outlined ? colorConfig.backgroundColor : colorConfig.textColor,
          ),
          SizedBox(width: sizeConfig.iconSpacing),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: sizeConfig.fontSize,
            fontWeight: FontWeight.w600,
            color: outlined ? colorConfig.backgroundColor : colorConfig.textColor,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );

    Widget badge = Container(
      padding: sizeConfig.padding,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : colorConfig.backgroundColor,
        border: outlined
          ? Border.all(
              color: colorConfig.backgroundColor,
              width: 1.5,
            )
          : null,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusFull),
      ),
      child: child,
    );

    if (onTap != null) {
      badge = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusFull),
          splashColor: colorConfig.backgroundColor.withValues(alpha: 0.2),
          highlightColor: colorConfig.backgroundColor.withValues(alpha: 0.1),
          child: badge,
        ),
      );
    }

    return badge;
  }

  _ColorConfig _getColorConfig() {
    switch (variant) {
      case ModernBadgeVariant.primary:
        return _ColorConfig(
          backgroundColor: AppTheme.primaryColor,
          textColor: Colors.white,
        );
      case ModernBadgeVariant.secondary:
        return _ColorConfig(
          backgroundColor: AppTheme.secondaryColor,
          textColor: Colors.white,
        );
      case ModernBadgeVariant.success:
        return _ColorConfig(
          backgroundColor: AppTheme.successColor,
          textColor: Colors.white,
        );
      case ModernBadgeVariant.warning:
        return _ColorConfig(
          backgroundColor: AppTheme.warningColor,
          textColor: Colors.white,
        );
      case ModernBadgeVariant.error:
        return _ColorConfig(
          backgroundColor: AppTheme.errorColor,
          textColor: Colors.white,
        );
      case ModernBadgeVariant.info:
        return _ColorConfig(
          backgroundColor: AppTheme.infoColor,
          textColor: Colors.white,
        );
      case ModernBadgeVariant.neutral:
        return _ColorConfig(
          backgroundColor: AppTheme.borderDarkColor,
          textColor: AppTheme.primaryTextColor,
        );
    }
  }

  _SizeConfig _getSizeConfig() {
    switch (size) {
      case ModernBadgeSize.small:
        return _SizeConfig(
          fontSize: 10,
          iconSize: AppTheme.iconXs,
          iconSpacing: AppTheme.spacingXs,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXs,
          ),
        );
      case ModernBadgeSize.medium:
        return _SizeConfig(
          fontSize: 12,
          iconSize: AppTheme.iconSm,
          iconSpacing: AppTheme.spacingVerySmall,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSmall,
            vertical: AppTheme.spacingXs,
          ),
        );
      case ModernBadgeSize.large:
        return _SizeConfig(
          fontSize: 14,
          iconSize: AppTheme.iconMd,
          iconSpacing: AppTheme.spacingSm,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSmall,
          ),
        );
    }
  }
}

/// A notification badge with a count indicator
class ModernNotificationBadge extends StatelessWidget {
  const ModernNotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.showZero = false,
    this.maxCount = 99,
    this.offset,
    this.color,
    this.textColor,
  });

  final Widget child;
  final int count;
  final bool showZero;
  final int maxCount;
  final Offset? offset;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !showZero) {
      return child;
    }

    final displayCount = count > maxCount ? '$maxCount+' : count.toString();
    final effectiveColor = color ?? AppTheme.errorColor;
    final effectiveTextColor = textColor ?? Colors.white;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: (offset?.dy ?? -8),
          right: (offset?.dx ?? -8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: AppTheme.spacingXs,
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusFull),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                displayCount,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A status indicator badge (dot only)
class ModernStatusBadge extends StatelessWidget {
  const ModernStatusBadge({
    super.key,
    required this.child,
    this.status = ModernBadgeVariant.success,
    this.size = 12.0,
    this.offset,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  final Widget child;
  final ModernBadgeVariant status;
  final double size;
  final Offset? offset;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final statusColor = ModernBadge(
      text: '',
      variant: status,
    )._getColorConfig().backgroundColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: (offset?.dy ?? 0),
          right: (offset?.dx ?? 0),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: borderColor != null
                ? Border.all(
                    color: borderColor!,
                    width: borderWidth,
                  )
                : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// A chip-style badge for tags or filters
class ModernChip extends StatelessWidget {
  const ModernChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDelete,
    this.avatar,
    this.backgroundColor,
    this.selectedColor,
    this.textColor,
    this.deleteIcon,
    this.size = ModernBadgeSize.medium,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Widget? avatar;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? textColor;
  final IconData? deleteIcon;
  final ModernBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final sizeConfig = _getSizeConfig();

    final effectiveBackgroundColor = selected
      ? (selectedColor ?? AppTheme.primaryLightColor)
      : (backgroundColor ?? AppTheme.borderLightColor);

    final effectiveTextColor = selected
      ? Colors.white
      : (textColor ?? AppTheme.primaryTextColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusFull),
        splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        highlightColor: AppTheme.primaryColor.withValues(alpha: 0.05),
        child: Container(
          padding: sizeConfig.padding,
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusFull),
            border: selected
              ? Border.all(
                  color: AppTheme.primaryColor,
                  width: 1.5,
                )
              : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatar != null) ...[
                SizedBox(
                  width: sizeConfig.avatarSize,
                  height: sizeConfig.avatarSize,
                  child: avatar,
                ),
                SizedBox(width: sizeConfig.spacing),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: sizeConfig.fontSize,
                  fontWeight: FontWeight.w600,
                  color: effectiveTextColor,
                ),
              ),
              if (onDelete != null) ...[
                SizedBox(width: sizeConfig.spacing),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    deleteIcon ?? Icons.close,
                    size: sizeConfig.iconSize,
                    color: effectiveTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _ChipSizeConfig _getSizeConfig() {
    switch (size) {
      case ModernBadgeSize.small:
        return _ChipSizeConfig(
          fontSize: 12,
          iconSize: AppTheme.iconSm,
          avatarSize: 16,
          spacing: AppTheme.spacingXs,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSmall,
            vertical: AppTheme.spacingXs,
          ),
        );
      case ModernBadgeSize.medium:
        return _ChipSizeConfig(
          fontSize: 14,
          iconSize: AppTheme.iconMd,
          avatarSize: 20,
          spacing: AppTheme.spacingSm,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
        );
      case ModernBadgeSize.large:
        return _ChipSizeConfig(
          fontSize: 16,
          iconSize: AppTheme.iconLg,
          avatarSize: 24,
          spacing: AppTheme.spacingSmall,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingSmall,
          ),
        );
    }
  }
}

class _ColorConfig {
  final Color backgroundColor;
  final Color textColor;

  _ColorConfig({
    required this.backgroundColor,
    required this.textColor,
  });
}

class _SizeConfig {
  final double fontSize;
  final double iconSize;
  final double iconSpacing;
  final EdgeInsetsGeometry padding;

  _SizeConfig({
    required this.fontSize,
    required this.iconSize,
    required this.iconSpacing,
    required this.padding,
  });
}

class _ChipSizeConfig {
  final double fontSize;
  final double iconSize;
  final double avatarSize;
  final double spacing;
  final EdgeInsetsGeometry padding;

  _ChipSizeConfig({
    required this.fontSize,
    required this.iconSize,
    required this.avatarSize,
    required this.spacing,
    required this.padding,
  });
}