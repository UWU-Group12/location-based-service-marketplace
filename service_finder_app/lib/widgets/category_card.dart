import 'package:flutter/material.dart';

import '../models/service_category_model.dart';
import '../services/storage_service.dart';

class CategoryCard extends StatelessWidget {
  static const double radius = 8;
  static const double labelHorizontalPadding = 18;

  final ServiceCategory category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  static double imageHeight(double width) => width * 0.76;

  static double labelHeight(BuildContext context, double width) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 3.0);
    return (width * 0.45) + (10 * (textScale - 1));
  }

  static double tileHeight(BuildContext context, double width) {
    return imageHeight(width) + labelHeight(context, width);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return SizedBox(
                    height: imageHeight(width),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: _CategoryImage(category: category),
                    ),
                  );
                },
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Container(
                    height: labelHeight(context, width),
                    color: Colors.white,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: labelHorizontalPadding,
                    ),
                    child: Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryCardRow extends StatelessWidget {
  static const double gap = 16;

  final List<ServiceCategory> categories;
  final void Function(ServiceCategory category) onTapCategory;

  const CategoryCardRow({
    super.key,
    required this.categories,
    required this.onTapCategory,
  });

  static double cardWidth(double availableWidth) {
    return (availableWidth - (2 * gap)) / 2.8;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = cardWidth(constraints.maxWidth);
        return SizedBox(
          height: CategoryCard.tileHeight(context, width),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: gap),
            itemBuilder: (context, index) {
              final category = categories[index];
              return SizedBox(
                width: width,
                child: CategoryCard(
                  category: category,
                  onTap: () => onTapCategory(category),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryImage extends StatefulWidget {
  final ServiceCategory category;

  const _CategoryImage({required this.category});

  @override
  State<_CategoryImage> createState() => _CategoryImageState();
}

class _CategoryImageState extends State<_CategoryImage> {
  late Future<String?> _imageUrlFuture;

  @override
  void initState() {
    super.initState();
    _imageUrlFuture = _loadImageUrl();
  }

  @override
  void didUpdateWidget(_CategoryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category.iconPath != widget.category.iconPath) {
      _imageUrlFuture = _loadImageUrl();
    }
  }

  Future<String?> _loadImageUrl() async {
    final imagePath = widget.category.iconPath.trim();
    if (imagePath.isEmpty) return null;
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    return StorageService().getDownloadUrl(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imageUrlFuture,
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;
        if (imageUrl == null || snapshot.hasError) {
          return Icon(
            Icons.home_repair_service,
            color: Colors.black.withValues(alpha: 0.55),
            size: 34,
          );
        }

        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.home_repair_service,
              color: Colors.black.withValues(alpha: 0.55),
              size: 34,
            );
          },
        );
      },
    );
  }
}
