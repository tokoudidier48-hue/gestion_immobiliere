class Unites {
  int? id;
  String nomUnite;
  String typeUnite;
  String adresse;
  double loyer;
  String description;
  int nbrAvances;
  String typeDouche;
  String typeCaution;
  double montantCaution;
  bool prepaye;
  bool garage;
  String contratLocation;
  bool statut;
  DateTime dateCreation;

  Unites({
    this.id,
    required this.nomUnite,
    required this.typeUnite,
    required this.adresse,
    required this.loyer,
    required this.description,
    required this.nbrAvances,
    required this.typeDouche,
    required this.typeCaution,
    required this.montantCaution,
    required this.prepaye,
    required this.garage,
    required this.contratLocation,
    required this.statut,
    required this.dateCreation,
  });

  // Convertir Json en model
  factory Unites.fromJson(Map<String, dynamic> json) {
    return Unites(
      id: json['id'],
      nomUnite: json['nom_unite'],
      typeUnite: json['type_unite'],
      adresse: json['adresse'],
      loyer: json['loyer'].toDouble(),
      description: json['description'],
      nbrAvances: json['nbr_avances'],
      typeDouche: json['type_douche'],
      typeCaution: json['type_caution'],
      montantCaution: json['montant_caution'].toDouble(),
      prepaye: json['prepaye'],
      garage: json['garage'],
      contratLocation: json['contrat_location'],
      statut: json['statut'],
      dateCreation: DateTime.parse(json['date_creation']),
    );  
  }

  // Convertir model en Json
  Map<String, dynamic> toJson() {
    return {
      'nom_unite': nomUnite,
      'type_unite': typeUnite,
      'adresse': adresse,
      'loyer': loyer,
      'description': description,
      'nbr_avances': nbrAvances,
      'type_douche': typeDouche,
      'type_caution': typeCaution,
      'montant_caution': montantCaution,
      'prepaye': prepaye,
      'garage': garage,
      'contrat_location': contratLocation,
      'statut': statut,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  

}