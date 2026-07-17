class CategorySuggestion {
  final String category;
  final String reason;

  const CategorySuggestion({required this.category, required this.reason});

  factory CategorySuggestion.fromJson(Map<String, dynamic> json) {
    return CategorySuggestion(
      category: json['category'] ?? "Other",
      reason: json['reason'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {"category": category, "reason": reason};
  }
}
