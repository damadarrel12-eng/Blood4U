import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String name;
  String email;
  String bloodType;
  double lat;
  double lng;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.bloodType,
    required this.lat,
    required this.lng,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final geopoint = map['location'] as GeoPoint?;
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      bloodType: map['bloodType'] ?? '',
      lat: geopoint?.latitude ?? 0,
      lng: geopoint?.longitude ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'bloodType': bloodType,
      'location': GeoPoint(lat, lng),
    };
  }
}