import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/provider_model.dart';
import '../services/storage_service.dart';

class ProviderProfileImage extends StatefulWidget {
  final ProviderModel provider;
  final double radius;

  const ProviderProfileImage({
    super.key,
    required this.provider,
    required this.radius,
  });

  @override
  State<ProviderProfileImage> createState() => _ProviderProfileImageState();
}

class _ProviderProfileImageState extends State<ProviderProfileImage> {
  final StorageService _storageService = StorageService();

  late Future<String?> _imageUrlFuture;

  @override
  void initState() {
    super.initState();
    _imageUrlFuture = _loadImageUrl();
  }

  @override
  void didUpdateWidget(ProviderProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.provider.profileImagePath !=
        widget.provider.profileImagePath) {
      _imageUrlFuture = _loadImageUrl();
    }
  }

  Future<String?> _loadImageUrl() async {
    final imagePath = widget.provider.profileImagePath?.trim();
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    return _storageService.getDownloadUrl(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imageUrlFuture,
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;

        if (imageUrl == null || snapshot.hasError) {
          return _buildFallback(
            isLoading: snapshot.connectionState == ConnectionState.waiting,
          );
        }

        return ClipOval(
          child: Image.network(
            imageUrl,
            width: widget.radius * 2,
            height: widget.radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          ),
        );
      },
    );
  }

  Widget _buildFallback({bool isLoading = false}) {
    final displayName = widget.provider.displayName.trim();
    final initial = displayName.isEmpty ? '?' : displayName[0].toUpperCase();

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.primary,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.radius * 0.65,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
