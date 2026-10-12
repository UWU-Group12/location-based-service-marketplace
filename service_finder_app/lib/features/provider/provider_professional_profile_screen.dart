import 'package:flutter/material.dart';

import '../../widgets/profile_editor_scaffold.dart';

class ProviderProfessionalProfileScreen extends StatefulWidget {
  final String bio;
  final String categoryNames;
  final Future<void> Function(String) onSave;
  const ProviderProfessionalProfileScreen({
    super.key,
    required this.bio,
    required this.categoryNames,
    required this.onSave,
  });

  @override
  State<ProviderProfessionalProfileScreen> createState() =>
      _ProviderProfessionalProfileScreenState();
}

class _ProviderProfessionalProfileScreenState
    extends State<ProviderProfessionalProfileScreen> {
  late final _bio = TextEditingController(text: widget.bio);
  bool _saving = false;

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.onSave(_bio.text.trim());
      if (!mounted) return;
      setState(() => _saving = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save your professional profile. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ProfileEditorScaffold(
    title: 'Professional profile',
    saving: _saving,
    onSave: _save,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _bio,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Professional bio',
            hintText: 'Tell customers about your experience',
            prefixIcon: Icon(Icons.description_outlined),
          ),
        ),
        const SizedBox(height: 24),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Service category',
            prefixIcon: Icon(Icons.home_repair_service_outlined),
          ),
          child: Text(
            widget.categoryNames.isEmpty
                ? 'Not provided'
                : widget.categoryNames,
          ),
        ),
      ],
    ),
  );
}
