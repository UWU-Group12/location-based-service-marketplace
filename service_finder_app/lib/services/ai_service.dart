import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/category_suggestion_model.dart';
import 'firestore_service.dart';

class AIService {
  final String workerUrl =
      "https://dry-tooth-cd62.hansikachathumina.workers.dev";
  final FirestoreService _firestoreService = FirestoreService();

  Future<CategorySuggestion?> suggestCategory(String description) async {
    try {
      final categories = await _firestoreService.getActiveCategories();
      final categoryList = categories
          .map((category) => category.name)
          .join("\n");

      final response = await http.post(
        Uri.parse(workerUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "prompt":
              """

You are a service category assistant.

Choose ONLY one category from this list:

$categoryList

Other


Customer problem:

$description


Return JSON only:

{
"category":"",
"reason":""
}

""",
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(response.body);

        return null;
      }

      final result = jsonDecode(response.body);

      String answer = result["answer"];

      answer = answer.replaceAll("```json", "").replaceAll("```", "").trim();

      final jsonData = jsonDecode(answer);

      return CategorySuggestion.fromJson(jsonData);
    } catch (e) {
      debugPrint("Category AI Error: $e");

      return null;
    }
  }

  Future<String?> improveDescription(String description) async {
    try {
      final response = await http.post(
        Uri.parse(workerUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "prompt":
              """

Improve this service request description.

Rules:
- Keep original meaning.
- Do not add new information.
- Do not add price.


Input:

$description


Return only improved description.

""",
        }),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final result = jsonDecode(response.body);

      return result["answer"];
    } catch (e) {
      debugPrint("Description AI Error: $e");

      return null;
    }
  }
}
