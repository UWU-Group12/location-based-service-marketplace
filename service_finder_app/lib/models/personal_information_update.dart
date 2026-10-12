import 'dart:io';

class PersonalInformationUpdate {
  final String name;
  final String phone;
  final File? image;
  final bool clearPhoto;

  const PersonalInformationUpdate({
    required this.name,
    required this.phone,
    this.image,
    this.clearPhoto = false,
  });
}
