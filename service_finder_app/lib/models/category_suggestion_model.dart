class CategorySuggestion {
  final String? categoryId;
  final String category;
  final String reason;

  const CategorySuggestion({
    this.categoryId,
    required this.category,
    required this.reason,
  });

  factory CategorySuggestion.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final reason = json['reason'];

    return CategorySuggestion(
      category: category is String && category.trim().isNotEmpty
          ? category.trim()
          : 'Other',
      reason: reason is String ? reason.trim() : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (categoryId != null) 'categoryId': categoryId,
      'category': category,
      'reason': reason,
    };
  }

  CategorySuggestion withCategory({
    required String categoryId,
    required String category,
  }) {
    return CategorySuggestion(
      categoryId: categoryId,
      category: category,
      reason: reason,
    );
  }
}
