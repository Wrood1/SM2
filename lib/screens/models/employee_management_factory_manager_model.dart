// model.dart

class Person {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String position;
  final String? factoryManagerId;

  Person({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.position,
    this.factoryManagerId,
  });

  factory Person.fromMap(Map<String, dynamic> map, String id) {
    return Person(
      id: id,
      name: map['name'] ?? 'No name',
      email: map['email'] ?? 'No email',
      profileImage: map['profileImage'],
      position: map['position'] ?? '',
      factoryManagerId: map['factoryManagerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'position': position,
      'factoryManagerId': factoryManagerId,
    };
  }
}
