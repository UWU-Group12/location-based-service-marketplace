# AI Feature Requirements

## Project: Work Around

## 1. Overview
This document defines the requirements for two AI-assisted features in the Work Around service marketplace application:
1. AI Service Category Suggestion
2. AI Request Description Improvement

The AI features provide assistance only. The customer has full control over accepting, editing, or changing AI-generated suggestions.

---

# 2. AI Feature 1: Service Category Suggestion

## Purpose
Help customers select the most suitable service category based on their problem description.

## Input
Customer problem statement.

Example:
"My kitchen sink is leaking under the pipe."

## Process
1. Customer enters a problem description.
2. System sends the text input to the AI service.
3. AI analyzes the problem.
4. AI selects a category from the available service category list.
5. System displays the suggested category.
6. Customer accepts or manually changes the category.

## Output
A valid service category.

Example:
{
  "category": "Plumber",
  "reason": "The request describes a leaking water pipe."
}

## AI Limitations
- AI cannot create new categories.
- AI cannot assign workers automatically.
- Final category decision belongs to the customer.

## Fallback Method
If AI fails, the customer can manually select a category.

---

# 3. AI Feature 2: Request Description Improvement

## Purpose
Improve unclear or short customer descriptions into clear service requests.

## Input
Customer short request description.

Example:
"Water leaking kitchen."

## Process
1. Customer enters a short description.
2. System sends the description to AI.
3. AI improves the text using clear language.
4. System displays the improved description.
5. Customer reviews and edits if required.
6. Customer confirms the final description.

## Output
Improved service request description.

Example:
{
  "improvedDescription": "Water is leaking from the pipe below the kitchen sink."
}

## AI Limitations
- AI should keep the original meaning.
- AI should not add information not provided by the customer.
- AI should not include prices or technical conclusions.

## Fallback Method
Customer can manually enter the service description.

---

# 4. Service Categories for AI

Allowed categories:

| Category | Keywords |
|---|---|
| Plumber | leak, pipe, tap, sink, water |
| Electrician | wire, socket, power, switch |
| Carpenter | door, cupboard, table, furniture |
| Painter | wall, paint, colour, ceiling |
| Mason | brick, concrete, wall, cement |
| Mobile Repair Technician | screen, battery, charging, phone |
| Appliance Repair Technician | machine, fridge, washing machine |
| Welder | metal, welding |
| Cleaner | cleaning, house |
| Other | Unknown requests |

---

# 5. User Control Requirements

- Users must review AI-generated content.
- Users can edit AI suggestions.
- AI output cannot be submitted automatically.
- Final decisions are made by customers.

---

# 6. AI Failure Handling

If AI service is unavailable:
- Show an error message.
- Allow manual category selection.
- Allow manual description entry.
- Do not block service request creation.

---

# 7. Expected Database Fields

Possible service request fields:

- originalDescription
- improvedDescription
- selectedCategoryId
- aiSuggestedCategoryId
- usedAiCategorySuggestion
- usedAiDescriptionGenerator

The system stores the final customer-confirmed information.

---

# 8. Testing Requirements

## Category Suggestion Tests

| Test Input | Expected Result |
|---|---|
| Pipe is leaking below sink | Plumber |
| Wall socket has no power | Electrician |
| Wooden door will not close | Carpenter |

## Description Improvement Tests

| Test Input | Expected Result |
|---|---|
| Sink leaking | Clear plumbing request |
| Water leaking kitchen | Improved clear description |
| Empty text | Validation message |

---

# 9. AI Role Summary

| Feature | AI Role | Customer Role |
|---|---|---|
| Category Suggestion | Suggest category | Accept or change category |
| Description Improvement | Improve wording | Review and confirm final text |

