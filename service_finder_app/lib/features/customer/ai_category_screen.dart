import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_router.dart';
import '../../models/category_suggestion_model.dart';
import '../../services/ai_service.dart';

class AiCategoryScreen extends StatefulWidget {
  const AiCategoryScreen({super.key});

  @override
  State<AiCategoryScreen> createState() => _AiCategoryScreenState();
}

class _AiCategoryScreenState extends State<AiCategoryScreen> {
  final TextEditingController _problemController = TextEditingController();

  final int _maxCharacters = 500;

  final AIService _aiService = AIService();

  CategorySuggestion? _categorySuggestion;

  bool _isLoading = false;

  Future<void> _requestSuggestion() async {
    if (_isLoading || _problemController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final result = await _aiService.suggestCategory(_problemController.text);
    if (!mounted) return;

    setState(() {
      _categorySuggestion = result;
      _isLoading = false;
    });
  }

  void _openSuggestedCategory() {
    final suggestion = _categorySuggestion;
    if (suggestion == null) return;

    final categoryId = suggestion.categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      AppRouter.goToServiceCategoryScreen(context);
      return;
    }

    AppRouter.goToProviderListScreen(
      context,
      categoryId: categoryId,
      categoryName: suggestion.category,
    );
  }

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final suggestion = _categorySuggestion;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Describe Your Problem',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          // Intro card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.providerCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Tell us what is wrong and we will help you find the right service.",
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _heading('Your problem'),
          _card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                TextField(
                  controller: _problemController,
                  maxLines: 8,
                  maxLength: _maxCharacters,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Tell us what problem you are facing...",
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: AppColors.hint,
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.all(20),

                    // Ignore global InputDecorationTheme
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,

                    counterText: "",
                  ),
                ),
                const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: AppColors.border,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "You can review and change the AI suggestion.",
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        "${_problemController.text.length}/$_maxCharacters",
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Primary action button (shape and colors from the app theme)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _requestSuggestion,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isLoading ? "Thinking..." : "Ask AI"),
          ),

          // Results only appear once Ask AI has returned a suggestion
          if (suggestion != null) ...[
            const SizedBox(height: 32),
            _heading('AI suggestion'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.home_repair_service_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion.category,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    suggestion.reason,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openSuggestedCategory,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                      ),
                      icon: Icon(
                        suggestion.categoryId == null
                            ? Icons.grid_view_outlined
                            : Icons.people_outline,
                      ),
                      label: Text(
                        suggestion.categoryId == null
                            ? 'Browse Service Categories'
                            : 'View Available Providers',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _heading('Recommended professionals'),
            _card(
              child: _mutedText(
                "Use the suggestion button above to see matching service providers.",
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Same section heading as the profile screen
  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    ),
  );

  // Same bordered card as the provider dashboard
  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _mutedText(String text) => Text(
    text,
    style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
  );
}
