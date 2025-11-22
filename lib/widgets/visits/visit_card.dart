import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/client/client_avatar.dart';
import '../../l10n/app_localizations.dart';

class VisitCard extends StatelessWidget {
  final Visit visit;
  final Client? client; // Optional - for staff view where we show client info
  final void Function(Visit)? onToggleLoved; // Optional - for client view
  final VoidCallback? onTap; // Optional custom tap handler

  const VisitCard({
    super.key,
    required this.visit,
    this.client,
    this.onToggleLoved,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderLightColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {
            context.pushNamed(
              'visit_details',
              pathParameters: {'visitId': visit.id},
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with client info (for staff view) or service badge
                if (client != null)
                  _buildClientHeader(context, l10n)
                else
                  _buildServiceHeader(context),

                // Rating and staff info row
                if (visit.staffId != null || visit.rating != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (visit.rating != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                visit.rating.toString(),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (visit.staffId != null && client != null)
                        Expanded(child: _buildStaffInfo(context, l10n)),
                    ],
                  ),
                ],

                // Photo preview
                if (visit.photos != null && visit.photos!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildPhotoPreview(context, visit.photos!),
                ],

                // Notes preview (for staff view)
                if (client != null && visit.notes != null && visit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.borderLightColor,
                      ),
                    ),
                    child: Text(
                      visit.notes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppTheme.secondaryTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // Time at bottom
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: AppTheme.mutedTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            visit.simpleTimeFormat(l10n),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.mutedTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Client header for staff view
  Widget _buildClientHeader(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        // Client avatar
        if (client != null) ...[
          ClientAvatar(
            client: client!,
            size: 32,
            showBorder: true,
          ),
          const SizedBox(width: AppTheme.spacingMedium),
        ],

        // Client and service info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client?.fullName ?? 'Unknown Client',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (visit.serviceName != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    visit.serviceName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Loved status for staff view
        if (visit.loved == true) ...[
          const SizedBox(width: AppTheme.spacingSmall),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.favorite,
              color: Colors.red,
              size: 14,
            ),
          ),
        ],
      ],
    );
  }

  // Service header for client view
  Widget _buildServiceHeader(BuildContext context) {
    return Row(
      children: [
        // Service badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            visit.shortDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const Spacer(),
        // Heart icon with subtle background (only for client view)
        if (onToggleLoved != null)
          GestureDetector(
            onTap: () => onToggleLoved!(visit),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (visit.loved ?? false)
                  ? Colors.red.withValues(alpha: 0.1)
                  : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                (visit.loved ?? false) ? Icons.favorite : Icons.favorite_border,
                color: (visit.loved ?? false) ? Colors.red : AppTheme.mutedTextColor,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoPreview(BuildContext context, List<Photo> photos) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          for (int i = 0; i < 2 && i < photos.length; i++) ...[
            Expanded(
              child: () {
                final photo = photos[i];
                final remainingCount = photos.length - 2;
                final showOverlay = i == 1 && remainingCount > 0;

                return Container(
                  height: 120,
                  margin: EdgeInsets.only(
                    right: i < 1 && photos.length > 1 ? AppTheme.spacingSmall : 0,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        _buildThumbnail(context, photo),
                        if (showOverlay)
                          _buildRemainingCountOverlay(context, remainingCount),
                      ],
                    ),
                  ),
                );
              }(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, Photo photo) {
    return FutureBuilder<String?>(
      future: context.read<VisitsProvider>().getPhotoUrl(photo.storagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryAccentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryAccentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            ),
            child: const Icon(
              Icons.broken_image,
              color: AppTheme.secondaryTextColor,
              size: 20,
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          child: CachedImage(
            imageUrl: snapshot.data!,
            width: 180,
            height: 180,
            fit: BoxFit.cover,
            placeholder: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryAccentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryAccentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              ),
              child: const Icon(
                Icons.broken_image,
                color: AppTheme.secondaryTextColor,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemainingCountOverlay(BuildContext context, int remainingCount) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          color: Colors.black.withValues(alpha: 0.6), // Semi-transparent overlay
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              '+$remainingCount',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffInfo(BuildContext context, AppLocalizations l10n) {
    return Consumer<StaffProvider>(
      builder: (context, staffProvider, child) {
        final staff = staffProvider.getStaffById(visit.staffId!);

        if (staff == null) {
          return Container(); // Staff not found
        }

        return Row(
          children: [
            Icon(
              Icons.person,
              size: 16,
              color: AppTheme.secondaryTextColor,
            ),
            const SizedBox(width: AppTheme.spacingVerySmall),
            Text(
              '${l10n.staff}: ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primaryAccentColor.withValues(alpha: 0.2),
              child: Text(
                staff.initials,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryButtonColor,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: Text(
                staff.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryTextColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}