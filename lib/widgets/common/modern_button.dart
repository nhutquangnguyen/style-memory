import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Enumeration for button variants
enum ModernButtonVariant {
  primary,
  secondary,
  tertiary,
  danger,
  success,
}

/// Enumeration for button sizes
enum ModernButtonSize {
  small,
  medium,
  large,
}

/// A modern, consistent button component with multiple variants and sizes
class ModernButton extends StatelessWidget {
  const ModernButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ModernButtonVariant.primary,
    this.size = ModernButtonSize.medium,
    this.icon,
    this.trailing,
    this.loading = false,
    this.fullWidth = false,
    this.disabled = false,
    this.borderRadius,
    this.gradient,
  });

  final String text;
  final VoidCallback? onPressed;
  final ModernButtonVariant variant;
  final ModernButtonSize size;
  final IconData? icon;
  final Widget? trailing;
  final bool loading;
  final bool fullWidth;
  final bool disabled;
  final BorderRadius? borderRadius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !disabled && !loading && onPressed != null;

    // Size configuration
    final sizeConfig = _getSizeConfig();

    // Color configuration based on variant
    final colorConfig = _getColorConfig();

    Widget buttonChild = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: sizeConfig.iconSize,
            height: sizeConfig.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorConfig.foregroundColor,
              ),
            ),
          )
        else if (icon != null)
          Icon(
            icon,
            size: sizeConfig.iconSize,
            color: colorConfig.foregroundColor,
          ),
        if ((loading || icon != null) && text.isNotEmpty)
          SizedBox(width: sizeConfig.spacing),
        if (text.isNotEmpty)
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: sizeConfig.fontSize,
                fontWeight: FontWeight.w600,
                color: colorConfig.foregroundColor,
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (trailing != null && text.isNotEmpty)
          SizedBox(width: sizeConfig.spacing),
        if (trailing != null) trailing!,
      ],
    );

    final borderRadius = this.borderRadius ??
      BorderRadius.circular(AppTheme.borderRadiusLarge);

    // Choose button type based on variant
    switch (variant) {
      case ModernButtonVariant.primary:
      case ModernButtonVariant.danger:
      case ModernButtonVariant.success:
        Widget button;

        if (gradient != null) {
          button = _buildGradientButton(
            buttonChild,
            colorConfig,
            sizeConfig,
            borderRadius,
            isEnabled,
          );
        } else {
          button = ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorConfig.backgroundColor,
              foregroundColor: colorConfig.foregroundColor,
              disabledBackgroundColor: AppTheme.borderColor,
              disabledForegroundColor: AppTheme.mutedTextColor,
              elevation: isEnabled ? AppTheme.elevationLow : 0,
              shadowColor: AppTheme.shadowColor,
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              padding: sizeConfig.padding,
              minimumSize: Size(
                fullWidth ? double.infinity : 0,
                sizeConfig.height,
              ),
            ),
            child: buttonChild,
          );
        }

        return fullWidth
          ? SizedBox(
              width: double.infinity,
              child: button,
            )
          : SizedBox(
              height: sizeConfig.height,
              child: button,
            );

      case ModernButtonVariant.secondary:
        Widget button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorConfig.foregroundColor,
            disabledForegroundColor: AppTheme.mutedTextColor,
            side: BorderSide(
              color: isEnabled
                ? colorConfig.borderColor
                : AppTheme.borderLightColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: sizeConfig.padding,
            minimumSize: Size(
              fullWidth ? double.infinity : 0,
              sizeConfig.height,
            ),
          ),
          child: buttonChild,
        );

        return fullWidth
          ? SizedBox(
              width: double.infinity,
              child: button,
            )
          : SizedBox(
              height: sizeConfig.height,
              child: button,
            );

      case ModernButtonVariant.tertiary:
        Widget button = TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: colorConfig.foregroundColor,
            disabledForegroundColor: AppTheme.mutedTextColor,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: sizeConfig.padding,
            minimumSize: Size(
              fullWidth ? double.infinity : 0,
              sizeConfig.height,
            ),
          ),
          child: buttonChild,
        );

        return fullWidth
          ? SizedBox(
              width: double.infinity,
              child: button,
            )
          : SizedBox(
              height: sizeConfig.height,
              child: button,
            );
    }
  }

  Widget _buildGradientButton(
    Widget child,
    _ColorConfig colorConfig,
    _SizeConfig sizeConfig,
    BorderRadius borderRadius,
    bool isEnabled,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: borderRadius,
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          height: sizeConfig.height,
          padding: sizeConfig.padding,
          decoration: BoxDecoration(
            gradient: isEnabled ? gradient : null,
            color: isEnabled ? null : AppTheme.borderColor,
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }

  _SizeConfig _getSizeConfig() {
    switch (size) {
      case ModernButtonSize.small:
        return _SizeConfig(
          height: 40,
          fontSize: 14,
          iconSize: AppTheme.iconSm,
          spacing: AppTheme.spacingSm,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSmall,
          ),
        );
      case ModernButtonSize.medium:
        return _SizeConfig(
          height: 52,
          fontSize: 16,
          iconSize: AppTheme.iconMd,
          spacing: AppTheme.spacingSmall,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLarge,
            vertical: AppTheme.spacingMd,
          ),
        );
      case ModernButtonSize.large:
        return _SizeConfig(
          height: 60,
          fontSize: 18,
          iconSize: AppTheme.iconLg,
          spacing: AppTheme.spacingMd,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingExtraLarge,
            vertical: AppTheme.spacingMedium,
          ),
        );
    }
  }

  _ColorConfig _getColorConfig() {
    switch (variant) {
      case ModernButtonVariant.primary:
        return _ColorConfig(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          borderColor: AppTheme.primaryColor,
        );
      case ModernButtonVariant.secondary:
        return _ColorConfig(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.primaryColor,
          borderColor: AppTheme.primaryColor,
        );
      case ModernButtonVariant.tertiary:
        return _ColorConfig(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.primaryColor,
          borderColor: Colors.transparent,
        );
      case ModernButtonVariant.danger:
        return _ColorConfig(
          backgroundColor: AppTheme.errorColor,
          foregroundColor: Colors.white,
          borderColor: AppTheme.errorColor,
        );
      case ModernButtonVariant.success:
        return _ColorConfig(
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          borderColor: AppTheme.successColor,
        );
    }
  }
}

/// Icon-only modern button variant
class ModernIconButton extends StatelessWidget {
  const ModernIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = ModernButtonVariant.tertiary,
    this.size = ModernButtonSize.medium,
    this.tooltip,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final ModernButtonVariant variant;
  final ModernButtonSize size;
  final String? tooltip;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final button = ModernButton(
      text: '',
      onPressed: onPressed,
      variant: variant,
      size: size,
      icon: icon,
      disabled: disabled,
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Floating action button variant
class ModernFab extends StatelessWidget {
  const ModernFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.label,
    this.mini = false,
    this.gradient,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final bool mini;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      // Extended FAB
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      );
    }

    // Regular FAB
    Widget fab = FloatingActionButton(
      onPressed: onPressed,
      mini: mini,
      backgroundColor: gradient == null ? AppTheme.primaryColor : null,
      foregroundColor: Colors.white,
      child: gradient != null
        ? Container(
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon),
          )
        : Icon(icon),
    );

    return fab;
  }
}

class _SizeConfig {
  final double height;
  final double fontSize;
  final double iconSize;
  final double spacing;
  final EdgeInsetsGeometry padding;

  _SizeConfig({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.spacing,
    required this.padding,
  });
}

class _ColorConfig {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  _ColorConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });
}