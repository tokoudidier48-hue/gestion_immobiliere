class Unites {
  int? id;
  int? proprieteId; // ← ajoute ça pour filtrer les unités par propriété
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
  String statut; // ← était bool, maintenant String
  DateTime dateCreation;
  String ville;
  String contactProprietaire;
  List<String> photos; // ← URLs des photos

  Unites({
    this.id,
    this.proprieteId, // ← ajoute ça
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
    required this.statut, // ← String
    required this.dateCreation,
    required this.ville,
    required this.contactProprietaire,
    this.photos = const [],
  });

  // Convertir Json en model
factory Unites.fromJson(Map<String, dynamic> json) {
  try {
    return Unites(
      id: json['id'],
      proprieteId: json['propriete'], // ← ajoute ça
      nomUnite: json['nom'] ?? '',
      typeUnite: json['type_unite'] ?? '',
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '',
      loyer: double.tryParse(json['loyer'].toString()) ?? 0.0,
      description: json['description'] ?? '',
      nbrAvances: int.tryParse(json['nombre_avances'].toString()) ?? 0,
      typeDouche: json['type_douche'] ?? '',
      typeCaution: json['type_caution'] ?? '',
      montantCaution: double.tryParse(json['prix_caution'].toString()) ?? 0.0,
      contactProprietaire: json['contact_proprietaire'] ?? '',
      prepaye: json['prepaye'].toString() == 'true',
      garage: json['garage'].toString() == 'true',
      contratLocation: json['contrat_location'] ?? '',
      statut: json['statut'] ?? 'libre',
      dateCreation: json['date_creation'] != null
          ? DateTime.parse(json['date_creation'])
          : DateTime.now(),
      photos: json['photos'] != null
    ? (json['photos'] as List)
        .map((p) => p['image'].toString())
        .toList()
    : [],
    );
  } catch (e) {
    print("==> Erreur fromJson sur : $json"); // ← affiche l'objet qui plante
    print("==> Erreur : $e");
    rethrow;
  }
}

  // Convertir model en Json
Map<String, dynamic> toJson() {
  return {
    'nom': nomUnite,                        // était 'nom_unite'
    'type_unite': typeUnite,
    'adresse': adresse,
    'ville': ville,                         // ← nouveau champ à ajouter
    'loyer': loyer.toInt(),                 // entier, pas décimal
    'nombre_avances': nbrAvances,           // était 'nbr_avances'
    'type_douche': typeDouche,
    'type_caution': typeCaution,
    'prix_caution': montantCaution.toInt(), // était 'montant_caution'
    'contact_proprietaire': contactProprietaire, // ← nouveau champ
    'prepaye': prepaye,
    'description': description,
  };
}

  

}

/*"id": 9,
        "nom": "ChamabreSalonSanitaire",
        "type_unite": "chambre_salon_sanitaire",
        "description": "Chambre salon confortable proche université de Parakou",
        "adresse": "Parakou/ZONGO",
        "ville": "Parakou",
        "type_douche": "interne",
        "prepaye": true,
        "garage": false,
        "loyer": "30000",
        "nombre_avances": 3,
        "type_caution": "eau_seule",
        "prix_caution": "15000",
        "contact_proprietaire": "0165202210",
        "statut": "libre",
        "proprietaire": 134,
        "proprietaire_nom": "Bariba TEKE",
        "propriete": 10,
        "propriete_nom": "Didier Batiment",
        "photos": [],
        "total_entree": 105000.0,
        "date_creation": "2026-03-30T15:50:27.369040+01:00",
        "date_modification": "2026-03-30T15:50:27.369059+01:00"*/