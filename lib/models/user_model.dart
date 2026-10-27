class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.contact,
    required this.bloodType,
    this.area = '',
    this.isDonorAvailable = false,
  });

  static const bloodTypes = <String>[
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  final String uid;
  final String name;
  final String email;
  final String contact;
  final String bloodType;
  final String area;
  final bool isDonorAvailable;

  factory UserModel.fromPrivateMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    return UserModel(
      uid: (map['uid'] as String?) ?? documentId,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      contact: (map['contact'] as String?) ?? '',
      bloodType: (map['bloodType'] as String?) ?? '',
      area: (map['area'] as String?) ?? '',
      isDonorAvailable: map['isDonorAvailable'] == true,
    );
  }

  factory UserModel.fromDonorMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    return UserModel(
      uid: (map['uid'] as String?) ?? documentId,
      name: (map['name'] as String?) ?? 'Blood4U donor',
      email: '',
      contact: '',
      bloodType: (map['bloodType'] as String?) ?? '',
      area: (map['area'] as String?) ?? '',
      isDonorAvailable: map['isAvailable'] == true,
    );
  }

  Map<String, dynamic> toPrivateMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'contact': contact,
        'bloodType': bloodType,
        'isDonorAvailable': isDonorAvailable,
      };

  Map<String, dynamic> toDonorMap({String area = ''}) => {
        'uid': uid,
        'name': name,
        'bloodType': bloodType,
        'area': area,
        'isAvailable': true,
      };
}
