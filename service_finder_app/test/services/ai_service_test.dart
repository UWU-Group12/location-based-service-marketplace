import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:service_finder_app/models/category_suggestion_model.dart';
import 'package:service_finder_app/models/service_category_model.dart';
import 'package:service_finder_app/services/ai_service.dart';

void main() {
  group('AIService category response parsing', () {
    test('accepts a structured answer returned by the worker', () {
      final responseBody = jsonEncode({
        'answer': {'category': 'Plumbing', 'reason': 'A leaking pipe.'},
      });

      final result = AIService.parseCategorySuggestionResponse(responseBody);

      expect(result?.category, 'Plumbing');
      expect(result?.reason, 'A leaking pipe.');
    });

    test('accepts a JSON string answer wrapped in a code fence', () {
      final responseBody = jsonEncode({
        'answer': '''```json
{"category":"Electrical","reason":"A wiring issue."}
```''',
      });

      final result = AIService.parseCategorySuggestionResponse(responseBody);

      expect(result?.category, 'Electrical');
      expect(result?.reason, 'A wiring issue.');
    });

    test('rejects malformed or incomplete response data', () {
      expect(AIService.parseCategorySuggestionResponse('not json'), isNull);
      expect(
        AIService.parseCategorySuggestionResponse(jsonEncode({'answer': 4})),
        isNull,
      );
    });

    test('uses safe values when answer fields have unexpected types', () {
      final responseBody = jsonEncode({
        'answer': {'category': 4, 'reason': false},
      });

      final result = AIService.parseCategorySuggestionResponse(responseBody);

      expect(result?.category, 'Other');
      expect(result?.reason, isEmpty);
    });
  });

  test('matches an AI category name to its Firestore category ID', () {
    const suggestion = CategorySuggestion(
      category: 'plumbing',
      reason: 'A leaking pipe.',
    );
    const categories = [
      ServiceCategory(
        id: 'plumber',
        name: 'Plumbing',
        description: '',
        iconPath: '',
        active: true,
        sortOrder: 1,
      ),
    ];

    final result = AIService.resolveCategorySuggestion(suggestion, categories);

    expect(result.categoryId, 'plumber');
    expect(result.category, 'Plumbing');
  });

  group('AIService description response parsing', () {
    test('returns a cleaned text answer', () {
      final responseBody = jsonEncode({
        'answer': '```text\nThe kitchen tap is leaking.\n```',
      });

      expect(
        AIService.parseDescriptionResponse(responseBody),
        'The kitchen tap is leaking.',
      );
    });

    test('rejects a non-text answer', () {
      final responseBody = jsonEncode({
        'answer': {'description': 'The kitchen tap is leaking.'},
      });

      expect(AIService.parseDescriptionResponse(responseBody), isNull);
    });
  });
}
