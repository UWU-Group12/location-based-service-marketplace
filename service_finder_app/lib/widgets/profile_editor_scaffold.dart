import 'package:flutter/material.dart';

/// Common chrome for editors; each screen owns its fields and save operation.
class ProfileEditorScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final bool saving;
  final bool busy;
  final VoidCallback onSave;

  const ProfileEditorScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.saving,
    this.busy = false,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: AbsorbPointer(
        absorbing: saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: FilledButton(
            onPressed: saving || busy ? null : onSave,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
