import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../services/avatar_service.dart';
import '../../theme/app_theme.dart';
import '../common/cached_image.dart';

class ClientAvatar extends StatefulWidget {
  final Client client;
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;

  const ClientAvatar({
    super.key,
    required this.client,
    this.size = 40,
    this.showBorder = false,
    this.onTap,
  }) : assert(size > 0, 'Avatar size must be positive');

  @override
  State<ClientAvatar> createState() => _ClientAvatarState();
}

class _ClientAvatarState extends State<ClientAvatar> {
  Future<String?>? _avatarUrlFuture;
  String? _cachedAvatarPath;

  @override
  void initState() {
    super.initState();
    _initializeAvatarUrl();
  }

  @override
  void didUpdateWidget(ClientAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if the avatar path changed
    if (oldWidget.client.avatarUrl != widget.client.avatarUrl) {
      _initializeAvatarUrl();
    }
  }

  void _initializeAvatarUrl() {
    if (widget.client.avatarUrl != null && widget.client.avatarUrl != _cachedAvatarPath) {
      _cachedAvatarPath = widget.client.avatarUrl;
      _avatarUrlFuture = AvatarService.getAvatarUrl(widget.client.avatarUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar();

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatar() {
    final container = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: widget.showBorder
            ? Border.all(
                color: AppTheme.primaryColor,
                width: 2.0,
              )
            : null,
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
      ),
      child: ClipOval(
        child: widget.client.avatarUrl != null && _avatarUrlFuture != null
            ? FutureBuilder<String?>(
                future: _avatarUrlFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingAvatar();
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    return CachedImage(
                      imageUrl: snapshot.data!,
                      fit: BoxFit.cover,
                      width: widget.size,
                      height: widget.size,
                      placeholder: _buildLoadingAvatar(),
                      errorWidget: _buildInitialsAvatar(),
                    );
                  }

                  return _buildInitialsAvatar();
                },
              )
            : _buildInitialsAvatar(),
      ),
    );

    return container;
  }

  Widget _buildInitialsAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.client.initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.4, // Scale font size with avatar size
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.borderLightColor,
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.4,
          height: widget.size * 0.4,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

// Large avatar for profile screens
class ClientAvatarLarge extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;

  const ClientAvatarLarge({
    super.key,
    required this.client,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClientAvatar(
          client: client,
          size: 80,
          showBorder: true,
          onTap: onTap,
        ),
        if (onTap != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}