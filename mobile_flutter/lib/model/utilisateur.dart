
class Utilisateur {
  int? id;
  String role;
  String name;
  String lastName;
  String email;
  String phoneNumber;
  String password;
  String confirmPassword;

  Utilisateur({
    this.id,
    required this.role,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
  });

  // Convertir Json en model
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'],
      role: json['role'],
      name: json['name'],
      lastName: json['last_name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      password: json['password'] ?? '',
      confirmPassword: json['confirmPassword'] ?? '',
    );
  }

  // Convertir model en Json
  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'name': name,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
    };
  }
}

