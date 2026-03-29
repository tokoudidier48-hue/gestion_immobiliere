class Propriete {
  int? id;
  String nomPropriete;

Propriete({
    this.id,
    required this.nomPropriete,
  });

// Convertir Json en model
  factory Propriete.fromJson(Map<String, dynamic> json) {
    return Propriete(
      id: json['id'],
      nomPropriete: json['nom_propriete'],
    );
  }

  // Convertir model en Json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_propriete': nomPropriete,
    };
  }

}