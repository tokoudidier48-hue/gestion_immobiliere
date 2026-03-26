class Propriete {
  int? id;
  String nomPropriete;
  DateTime dateCreation;

Propriete({
    this.id,
    required this.nomPropriete,
    required this.dateCreation,
  });

// Convertir Json en model
  factory Propriete.fromJson(Map<String, dynamic> json) {
    return Propriete(
      id: json['id'],
      nomPropriete: json['nom_propriete'],
      dateCreation: DateTime.parse(json['date_creation']),
    );
  }

  // Convertir model en Json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_propriete': nomPropriete,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

}