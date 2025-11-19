import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// Enumeration for input field variants
enum ModernInputVariant {
  outlined,
  filled,
}

/// A modern, consistent input field component
class ModernInput extends StatefulWidget {
  const ModernInput({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.variant = ModernInputVariant.outlined,
    this.borderRadius,
    this.contentPadding,
  });

  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final Widget? prefix;
  final Widget? suffix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ModernInputVariant variant;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<ModernInput> createState() => _ModernInputState();
}

class _ModernInputState extends State<ModernInput> {
  bool _obscureText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = widget.borderRadius ??
      BorderRadius.circular(AppTheme.borderRadiusLarge);

    Widget? suffixIcon = widget.suffixIcon;

    // Add password toggle if obscure text
    if (widget.obscureText) {
      suffixIcon = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: AppTheme.secondaryTextColor,
          size: AppTheme.iconMd,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: widget.errorText != null
                ? AppTheme.errorColor
                : AppTheme.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],
        Focus(
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          child: TextFormField(
            controller: widget.controller,
            initialValue: widget.initialValue,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            validator: widget.validator,
            inputFormatters: widget.inputFormatters,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.maxLength,
            obscureText: _obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: widget.enabled
                ? AppTheme.primaryTextColor
                : AppTheme.mutedTextColor,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              prefix: widget.prefix,
              suffix: widget.suffix,
              prefixIcon: widget.prefixIcon,
              suffixIcon: suffixIcon,
              contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingMd,
              ),
              // Custom styling based on variant
              filled: widget.variant == ModernInputVariant.filled,
              fillColor: widget.variant == ModernInputVariant.filled
                ? AppTheme.borderLightColor
                : AppTheme.surfaceColor,
              border: _getBorder(effectiveBorderRadius, false, false),
              enabledBorder: _getBorder(effectiveBorderRadius, false, false),
              focusedBorder: _getBorder(effectiveBorderRadius, true, false),
              errorBorder: _getBorder(effectiveBorderRadius, false, true),
              focusedErrorBorder: _getBorder(effectiveBorderRadius, true, true),
              disabledBorder: _getBorder(effectiveBorderRadius, false, false, disabled: true),
              // Label styling
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: _isFocused
                  ? AppTheme.primaryColor
                  : AppTheme.secondaryTextColor,
              ),
              floatingLabelStyle: theme.textTheme.labelMedium?.copyWith(
                color: widget.errorText != null
                  ? AppTheme.errorColor
                  : AppTheme.primaryColor,
              ),
              // Hint styling
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedTextColor,
              ),
              // Error styling
              errorStyle: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
              // Counter styling
              counterStyle: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ),
        ),
        if (widget.helperText != null && widget.errorText == null) ...[
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            widget.helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ],
    );
  }

  InputBorder _getBorder(
    BorderRadius borderRadius,
    bool focused,
    bool error, {
    bool disabled = false,
  }) {
    Color borderColor;
    double borderWidth;

    if (error) {
      borderColor = AppTheme.errorColor;
      borderWidth = focused ? 2.0 : 1.5;
    } else if (focused) {
      borderColor = AppTheme.primaryColor;
      borderWidth = 2.0;
    } else if (disabled) {
      borderColor = AppTheme.borderLightColor;
      borderWidth = 1.5;
    } else {
      borderColor = AppTheme.borderColor;
      borderWidth = 1.5;
    }

    if (widget.variant == ModernInputVariant.outlined) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: borderColor,
          width: borderWidth,
        ),
      );
    } else {
      return UnderlineInputBorder(
        borderSide: BorderSide(
          color: borderColor,
          width: borderWidth,
        ),
      );
    }
  }
}

/// A specialized search input field
class ModernSearchInput extends StatelessWidget {
  const ModernSearchInput({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ModernInput(
      hint: hint,
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      prefixIcon: const Icon(
        Icons.search,
        color: AppTheme.secondaryTextColor,
        size: AppTheme.iconMd,
      ),
      suffixIcon: controller?.text.isNotEmpty == true && onClear != null
        ? IconButton(
            icon: const Icon(
              Icons.clear,
              color: AppTheme.secondaryTextColor,
              size: AppTheme.iconMd,
            ),
            onPressed: onClear,
          )
        : null,
      variant: ModernInputVariant.filled,
    );
  }
}

/// A modern dropdown/select field
class ModernDropdown<T> extends StatelessWidget {
  const ModernDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.borderRadius,
    this.prefixIcon,
  });

  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final BorderRadius? borderRadius;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = borderRadius ??
      BorderRadius.circular(AppTheme.borderRadiusLarge);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: errorText != null
                ? AppTheme.errorColor
                : AppTheme.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingMd,
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
            border: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: const BorderSide(
                color: AppTheme.borderColor,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: const BorderSide(
                color: AppTheme.borderColor,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2.0,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: effectiveBorderRadius,
              borderSide: const BorderSide(
                color: AppTheme.borderLightColor,
                width: 1.5,
              ),
            ),
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: enabled
              ? AppTheme.primaryTextColor
              : AppTheme.mutedTextColor,
          ),
          dropdownColor: AppTheme.surfaceColor,
          icon: const Icon(
            Icons.expand_more,
            color: AppTheme.secondaryTextColor,
          ),
        ),
        if (helperText != null && errorText == null) ...[
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ],
    );
  }
}