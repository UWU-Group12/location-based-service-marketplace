import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../models/personal_information_update.dart';
import '../../widgets/profile_editor_scaffold.dart';

class PersonalInformationScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String email;
  final String? photoUrl;
  final bool requirePhone;
  final Future<void> Function(PersonalInformationUpdate) onSave;

  const PersonalInformationScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    this.photoUrl,
    this.requirePhone = false,
    required this.onSave,
  });

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _phone = TextEditingController(text: widget.phone);
  File? _image;
  bool _clearPhoto = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _photoOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            if (_image != null ||
                (!_clearPhoto && (widget.photoUrl?.isNotEmpty ?? false)))
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'remove') {
      setState(() {
        _image = null;
        _clearPhoto = true;
      });
      return;
    }
    try {
      final picked = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (!mounted || picked == null) return;
      setState(() {
        _image = File(picked.path);
        _clearPhoto = false;
      });
    } catch (_) {
      if (mounted) _message('Could not select a photo. Please try again.');
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.onSave(
        PersonalInformationUpdate(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          image: _image,
          clearPhoto: _clearPhoto,
        ),
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message('Could not save your personal information. Please try again.');
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final ImageProvider? photo = _image != null
        ? FileImage(_image!)
        : !_clearPhoto && (widget.photoUrl?.isNotEmpty ?? false)
        ? NetworkImage(widget.photoUrl!)
        : null;
    return ProfileEditorScaffold(
      title: 'Personal information',
      saving: _saving,
      onSave: _save,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                foregroundImage: photo,
                child: const Icon(
                  Icons.person_outline,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            Center(
              child: TextButton.icon(
                onPressed: _photoOptions,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Change profile photo'),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? 'Please enter your full name'
                  : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              initialValue: widget.email,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) =>
                  widget.requirePhone && (value?.trim().isEmpty ?? true)
                  ? 'Please enter your phone number'
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
