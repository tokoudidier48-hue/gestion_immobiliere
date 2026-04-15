from django.db import models
from comptes.models import Utilisateur
from proprietes.models import Propriete

class Unite(models.Model):
    TYPE_UNITE_CHOIX = [
        ('appartement', 'Appartement'),
        ('boutique', 'Boutique'),
        ('chambre_salon_sanitaire', 'Chambre salon sanitaire'),
        ('chambre_salon_ordinaire', 'Chambre salon ordinaire'),
        ('deux_chambres_sanitaire', 'Deux chambres salon sanitaire'),
        ('deux_chambres_ordinaire', 'Deux chambres salon ordinaire'),
        ('entree_coucher_sanitaire', 'Entrée coucher sanitaire'),
        ('entree_coucher_ordinaire', 'Entrée coucher ordinaire'),
    ]

    TYPE_DOUCHE_CHOIX = [
        ('interne', 'Interne'),
        ('externe', 'Externe'),
    ]

    TYPE_CAUTION_CHOIX = [
        ('eau_seule', 'Caution eau seule'),
        ('electricite_seule', "Caution d'électricité seule"),
        ('eau_et_electricite', 'Caution eau et électricité'),
    ]

    STATUT_CHOIX = [
        ('libre', 'Libre'),
        ('occupe', 'Occupé'),
        ('reserve', 'Réservé'),
        ('maintenance', 'En maintenance'),
    ]

    propriete = models.ForeignKey(
        Propriete,
        on_delete=models.CASCADE,
        related_name='unites',
        verbose_name="Propriété"
    )
    proprietaire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='unites',
        verbose_name="Propriétaire"
    )

    nom = models.CharField(max_length=200, verbose_name="Nom de l'unité")
    type_unite = models.CharField(
        max_length=50,
        choices=TYPE_UNITE_CHOIX,
        verbose_name="Type d'unité"
    )
    description = models.TextField(blank=True, verbose_name="Description")
    adresse = models.CharField(max_length=255, verbose_name="Adresse")
    ville = models.CharField(max_length=100, verbose_name="Ville")
    type_douche = models.CharField(
        max_length=20,
        choices=TYPE_DOUCHE_CHOIX,
        default='interne',
        verbose_name="Type de douche"
    )
    prepaye = models.BooleanField(
        default=False,
        verbose_name="Avec prépayé"
    )
    garage = models.BooleanField(
        default=False,
        verbose_name="Garage"
    )
    loyer = models.DecimalField(
        max_digits=10,
        decimal_places=0,
        verbose_name="Loyer mensuel (FCFA)"
    )
    nombre_avances = models.IntegerField(
        default=3,
        verbose_name="Nombre d'avances (mois)"
    )
    type_caution = models.CharField(
        max_length=30,
        choices=TYPE_CAUTION_CHOIX,
        verbose_name="Type de caution"
    )
    prix_caution = models.DecimalField(
        max_digits=10,
        decimal_places=0,
        verbose_name="Montant de la caution (FCFA)"
    )
    contact_proprietaire = models.CharField(
        max_length=20,
        verbose_name="Téléphone du propriétaire"
    )
    statut = models.CharField(
        max_length=20,
        choices=STATUT_CHOIX,
        default='libre',
        verbose_name="Statut"
    )
    date_creation = models.DateTimeField(auto_now_add=True)
    date_modification = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.get_type_unite_display()} - {self.nom}"

    def total_entree(self):
        return (self.loyer * self.nombre_avances) + self.prix_caution

    class Meta:
        verbose_name = "Unité"
        verbose_name_plural = "Unités"
        ordering = ['-date_creation']


class PhotoUnite(models.Model):
    unite = models.ForeignKey(
        Unite,
        on_delete=models.CASCADE,
        related_name='photos',
        verbose_name="Unité"
    )
    image = models.ImageField(
        upload_to='unites/',
        verbose_name="Photo"
    )
    est_principale = models.BooleanField(
        default=False,
        verbose_name="Photo principale"
    )
    ordre = models.IntegerField(
        default=0,
        verbose_name="Ordre d'affichage"
    )
    date_upload = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Photo {self.ordre} - {self.unite.nom}"

    class Meta:
        verbose_name = "Photo"
        verbose_name_plural = "Photos"
        ordering = ['ordre']