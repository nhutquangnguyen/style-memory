import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final int maxRating;
  final double size;
  final bool readOnly;
  final Function(int)? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 24.0,
    this.readOnly = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute evenly across full width
      children: List.generate(maxRating, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating;

        return GestureDetector(
          onTap: readOnly ? null : () => onRatingChanged?.call(starIndex),
          child: Icon(
            isFilled ? Icons.star : Icons.star_border,
            size: size,
            color: isFilled
                ? Colors.amber // Use amber/golden color for filled stars
                : Colors.grey.shade400,
          ),
        );
      }),
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final int initialRating;
  final int maxRating;
  final double size;
  final Function(int) onRatingChanged;
  final String? label;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.size = 32.0,
    required this.onRatingChanged,
    this.label,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
        ],
        Container(
          width: double.infinity, // Make it full width
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Center the content
            children: [
              StarRating(
                rating: _currentRating,
                maxRating: widget.maxRating,
                size: widget.size,
                onRatingChanged: (rating) {
                  setState(() {
                    _currentRating = rating;
                  });
                  widget.onRatingChanged(rating);
                },
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                _getRatingText(_currentRating),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getRatingColor(_currentRating),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
      case 2:
        return AppTheme.errorColor;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
        return Colors.green;
      default:
        return AppTheme.secondaryTextColor;
    }
  }
}