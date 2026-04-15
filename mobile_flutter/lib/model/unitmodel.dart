

enum UnitStatus { libre, occupe }
// Model de données pour une unité (appartement, boutique, etc.)
class UnitModel {
  final String name;
  final UnitStatus status;
  final String? locataire;
  final String? statusDetail;
  final String imagePath; // asset ou placeholder

  const UnitModel({
    required this.name,
    required this.status,
    this.locataire,
    this.statusDetail,
    required this.imagePath,
  });
}
// Liste d'exemple d'unités pour la démonstration

final List<UnitModel> units = [
  UnitModel(
    name: 'Appartement F3',
    status: UnitStatus.libre,
    statusDetail: 'Disponible immédiatement',
    imagePath: 'apt_f3',
  ),
  UnitModel(
    name: 'Boutique RDC',
    status: UnitStatus.occupe,
    locataire: 'Jean Dupont',
    imagePath: 'boutique_rdc',
  ),
  UnitModel(
    name: 'Chambre salon sa...',
    status: UnitStatus.occupe,
    locataire: 'Marie Nondo',
    imagePath: 'chambre_salon',
  ),
  UnitModel(
    name: 'Studio Meublé',
    status: UnitStatus.libre,
    statusDetail: 'Disponible sous 1 semaine',
    imagePath: 'studio_meuble',
  ),
  UnitModel(
    name: 'Local Commercial',
    status: UnitStatus.occupe,
    locataire: 'Bakery & Co',
    imagePath: 'local_commercial',
  ),
  UnitModel(
    name: 'Appartement T2',
    status: UnitStatus.libre,
    statusDetail: 'Disponible immédiatement',
    imagePath: 'apt_t2',
  ),
];