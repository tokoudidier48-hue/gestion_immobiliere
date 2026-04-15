
class Utilisateur {
  int? id;
  String role;
  String name;
  String lastName;
  String email;
  String phoneNumber;
  String? photoProfil;
  String password;
  String confirmPassword;
  DateTime? derniereConnexion;

  Utilisateur({
    this.id,
    required this.role,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.photoProfil,
    required this.password,
    required this.confirmPassword,
    this.derniereConnexion,
  });

  // Convertir Json en model
  factory Utilisateur.fromJson(Map<String, dynamic> json) {
  return Utilisateur(
    id: json['id'],
    role: json['role'],
    name: json['first_name'] ?? '',
    lastName: json['last_name'],
    email: json['email'],
    phoneNumber: json['telephone'], // ✅ cohérent avec backend
    photoProfil: json['photo_profil'],
    password: '',
    confirmPassword: '',
    derniereConnexion: json['derniere_connexion'] != null
        ? DateTime.parse(json['derniere_connexion'])
        : null,
  );
}

  // Convertir model en Json
  Map<String, dynamic> toJson() {
  return {
    'role': role,
    'first_name': name,
    'last_name': lastName,
    'email': email,
    'telephone': phoneNumber,        // ✅ corriger ici
    'photo_profil': photoProfil,
    'password': password,
    'password2': confirmPassword,    // ✅ ajouter ceci
  };
}
}

