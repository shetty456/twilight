class User {
  const User({
    required this.id,
    this.email,
    this.phone,
    this.displayName,
  });

  final String id;
  final String? email;
  final String? phone;
  final String? displayName;

  @override
  String toString() => 'User(id: $id, email: $email, phone: $phone)';
}
