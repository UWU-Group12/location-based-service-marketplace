import 'package:flutter/material.dart';
import 'provider_onboarding_layout.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_router.dart';
import '../../../models/service_category_model.dart';
import '../../../services/firestore_service.dart';
import '../provider_onboarding_provider.dart';

class ProviderProfileServiceInfo extends StatefulWidget {
  const ProviderProfileServiceInfo({super.key});

  @override
  State<ProviderProfileServiceInfo> createState() =>
      _ProviderProfileServiceInfoState();
}

class _ProviderProfileServiceInfoState
    extends State<ProviderProfileServiceInfo> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<ServiceCategory>> _categoriesFuture;
  String? _selectedCategoryId;
  bool _initialized = false;

  String get _query => _searchController.text.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _firestoreService.getActiveCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final onboarding = Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    );
    if (onboarding.selectedService.isNotEmpty) {
      _selectedCategoryId = onboarding.selectedService;
    }
    _initialized = true;
  }

  void _reloadCategories() {
    setState(() {
      _categoriesFuture = _firestoreService.getActiveCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _continue(List<ServiceCategory> categories) {
    final selectedCategoryId = _selectedCategoryId;
    final categoryIsActive = categories.any(
      (category) => category.id == selectedCategoryId,
    );

    if (selectedCategoryId == null || !categoryIsActive) return;

    Provider.of<ProviderOnboardingProvider>(
      context,
      listen: false,
    ).setService(selectedCategoryId);

    AppRouter.goToProviderProfileExperience(context);
  }

  Widget _buildCategoryList(List<ServiceCategory> categories) {
    if (categories.isEmpty) {
      return Column(
        children: [
          const Icon(
            Icons.category_outlined,
            size: 54,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No active service categories are available.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _reloadCategories,
            icon: const Icon(Icons.refresh),
            label: const Text('Reload'),
          ),
        ],
      );
    }

    final query = _query;
    final filteredCategories = query.isEmpty
        ? categories
        : categories.where((category) {
            return category.name.toLowerCase().contains(query) ||
                category.description.toLowerCase().contains(query);
          }).toList();
    final canContinue = categories.any(
      (category) => category.id == _selectedCategoryId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategorySearchField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        if (filteredCategories.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No matching categories',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _CategoryPickerList(
              categories: filteredCategories,
              selectedCategoryId: _selectedCategoryId,
              onSelected: (category) {
                FocusScope.of(context).unfocus();
                setState(() => _selectedCategoryId = category.id);
              },
            ),
          ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: canContinue ? () => _continue(categories) : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: ProviderOnboardingBody(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            const ProviderOnboardingHeroText(
              segments: [
                ProviderOnboardingHeroSegment('Select'),
                ProviderOnboardingHeroSegment('your'),
                ProviderOnboardingHeroSegment('service', muted: true),
                ProviderOnboardingHeroSegment('category'),
              ],
            ),
            const SizedBox(height: 28),
            FutureBuilder<List<ServiceCategory>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  final errorMessage = snapshot.error;

                  return Column(
                    children: [
                      Text(
                        'Could not load service categories: $errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _reloadCategories,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  );
                }

                return _buildCategoryList(snapshot.data ?? const []);
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _CategorySearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _CategorySearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search categories',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.045)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.045)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.focusedBorder),
        ),
      ),
    );
  }
}

class _CategoryPickerList extends StatelessWidget {
  final List<ServiceCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<ServiceCategory> onSelected;

  const _CategoryPickerList({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _CategoryWheelPicker(
      categories: categories,
      selectedCategoryId: selectedCategoryId,
      onSelected: onSelected,
    );
  }
}

class _CategoryWheelPicker extends StatefulWidget {
  final List<ServiceCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<ServiceCategory> onSelected;

  const _CategoryWheelPicker({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  State<_CategoryWheelPicker> createState() => _CategoryWheelPickerState();
}

class _CategoryWheelPickerState extends State<_CategoryWheelPicker> {
  static const double _itemExtent = 72;
  late FixedExtentScrollController _controller;

  int get _selectedIndex {
    final index = widget.categories.indexWhere(
      (category) => category.id == widget.selectedCategoryId,
    );
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void didUpdateWidget(_CategoryWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final categoriesChanged =
        oldWidget.categories.map((c) => c.id).join('|') !=
        widget.categories.map((c) => c.id).join('|');
    if (categoriesChanged ||
        oldWidget.selectedCategoryId != widget.selectedCategoryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients || widget.categories.isEmpty) {
          return;
        }
        _controller.animateToItem(
          _selectedIndex,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 330,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background,
                    Colors.white.withValues(alpha: 0.92),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              height: _itemExtent,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: _itemExtent,
            perspective: 0.0045,
            diameterRatio: 1.6,
            squeeze: 0.92,
            physics: const FixedExtentScrollPhysics(),
            overAndUnderCenterOpacity: 0.34,
            onSelectedItemChanged: (index) {
              if (index >= 0 && index < widget.categories.length) {
                widget.onSelected(widget.categories[index]);
              }
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: widget.categories.length,
              builder: (context, index) {
                if (index < 0 || index >= widget.categories.length) return null;
                final category = widget.categories[index];
                return _CategoryWheelItem(
                  category: category,
                  selected: category.id == widget.selectedCategoryId,
                  onTap: () {
                    _controller.animateToItem(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                    );
                    widget.onSelected(category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryWheelItem extends StatelessWidget {
  final ServiceCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryWheelItem({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: selected ? 25 : 21,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: -0.5,
            height: 1.1,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
