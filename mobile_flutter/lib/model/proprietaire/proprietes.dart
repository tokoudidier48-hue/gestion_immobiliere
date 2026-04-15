class Propriete {
  int? id;
  String nomPropriete;
  DateTime? dateCreation; // ← ajoute ça

Propriete({
    this.id,
    required this.nomPropriete,
    this.dateCreation, // ← ajoute ça
  });

// Convertir Json en model
  factory Propriete.fromJson(Map<String, dynamic> json) {
    return Propriete(
      id: int.tryParse(json['id'].toString()),
      nomPropriete: json['nom'],
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : null,
    );
  }

  // Convertir model en Json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nomPropriete,
    };
  }




}