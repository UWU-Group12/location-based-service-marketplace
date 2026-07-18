import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? phoneNumber;
  final String? photoPath;
  final String role; //customer or provider
  final String accountStatus; //active acc , suspended acc ,disabled acc
  final bool profileCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.phoneNumber,
    this.photoPath,
    required this.role,
    required this.accountStatus,
    required this.profileCompleted,
    required this.createdAt,
    required this.updatedAt,
});

factory UserModel.fromFirestore(String docId,Map <String ,dynamic>data){
  return UserModel(
    id: docId,
    displayName: data['displayName'] ?? 'user',
    email: data['email']?? '',
    phoneNumber: data['phoneNumber'],
    photoPath: data['photoPath'],
    role: data['role']?? 'customer',
    accountStatus: data['accountStatus']?? 'active',
    profileCompleted: data['profileCompleted']?? false,
    createdAt: (data['createdAt']as Timestamp).toDate(),
    updatedAt: (data['updatedAt']as Timestamp).toDate(),
  );
}
Map <String, dynamic>toFirestore(){
  return{
    'displayName': displayName,
    'email': email,
    'phoneNumber':phoneNumber,
    'photoPath': photoPath,
    'role': role,
    'accountStatus': accountStatus,
    'profileCompleted':profileCompleted,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt':Timestamp.fromDate(updatedAt),
  };
 }
}