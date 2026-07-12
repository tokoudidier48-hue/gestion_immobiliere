from rest_framework import serializers
from .models import Paiement, RecuRetrait, Recu, DemandeRemboursement, Remboursement
from locataires.models import Locataire
from locations.models import DemandeUnite


class PaiementSerializer(serializers.ModelSerializer):
    locataire_nom = serializers.CharField(source='locataire.get_full_name', read_only=True)
    proprietaire_nom = serializers.CharField(source='proprietaire.get_full_name', read_only=True)
    unite_nom = serializers.CharField(source='unite.nom', read_only=True)
    unite_photo = serializers.SerializerMethodField()

    class Meta:
        model = Paiement
        fields = [
            'id', 'locataire', 'locataire_nom', 'proprietaire', 'proprietaire_nom',
            'unite', 'unite_nom', 'unite_photo',
            'demande', 'type_paiement', 'mode_paiement', 'montant', 'numero_paiement',
            'statut', 'periode_debut', 'periode_fin', 'date_paiement', 'date_confirmation'
        ]
        read_only_fields = ['statut', 'date_paiement', 'date_confirmation']

    def get_unite_photo(self, obj):
        """Retourne l'URL de la première photo de l'unité (ou None)"""
        unite = obj.unite
        if unite and hasattr(unite, 'photos') and unite.photos.exists():
            premiere_photo = unite.photos.first()
            return premiere_photo.image.url if premiere_photo.image else None
        return None


class PaiementCreateSerializer(serializers.ModelSerializer):
    # Champ demande optionnel (peut être déduit automatiquement)
    demande = serializers.PrimaryKeyRelatedField(
        queryset=DemandeUnite.objects.all(),
        required=False,
        allow_null=True,
        write_only=True
    )

    class Meta:
        model = Paiement
        fields = [
            'unite', 'demande', 'type_paiement', 'mode_paiement', 'montant',
            'numero_paiement', 'periode_debut', 'periode_fin'
        ]

    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        
        # Vérifier que seul un locataire peut faire un paiement
        if user.role != 'locataire':
            raise serializers.ValidationError("Seuls les locataires peuvent effectuer un paiement.")

        unite = attrs['unite']
        type_paiement = attrs.get('type_paiement')
        mode_paiement = attrs.get('mode_paiement')
        
        # =========================================================
        # VALIDATION DE LA DEMANDE ACCEPTÉE
        # =========================================================
        demande = attrs.get('demande')
        
        if demande:
            # Vérifier que la demande correspond bien au locataire et à l'unité
            if demande.locataire != user:
                raise serializers.ValidationError(
                    "Cette demande ne vous appartient pas."
                )
            if demande.unite != unite:
                raise serializers.ValidationError(
                    "La demande ne correspond pas à l'unité spécifiée."
                )
            # Vérifier que la demande est acceptée
            if demande.statut != 'acceptee':
                raise serializers.ValidationError(
                    "La demande doit être acceptée par le propriétaire avant de pouvoir effectuer le paiement."
                )
            # Vérifier que la demande n'a pas déjà été payée
            if Paiement.objects.filter(
                demande=demande,
                statut__in=['valide', 'en_attente']
            ).exists():
                raise serializers.ValidationError(
                    "Un paiement a déjà été effectué pour cette demande."
                )
            # Stocker la demande pour la création
            attrs['_demande'] = demande
        else:
            # Si aucune demande n'est fournie, vérifier qu'il existe une demande acceptée
            demande_existante = DemandeUnite.objects.filter(
                locataire=user,
                unite=unite,
                statut='acceptee'
            ).first()
            
            if not demande_existante:
                raise serializers.ValidationError(
                    "Aucune demande acceptée trouvée pour cette unité. "
                    "Veuillez d'abord faire une demande."
                )
            
            # Vérifier que la demande n'a pas déjà été payée
            if Paiement.objects.filter(
                demande=demande_existante,
                statut__in=['valide', 'en_attente']
            ).exists():
                raise serializers.ValidationError(
                    "Un paiement a déjà été effectué pour votre demande."
                )
            
            # Stocker la demande pour la création
            attrs['_demande'] = demande_existante

        # =========================================================
        # VALIDATIONS SELON LE TYPE DE PAIEMENT
        # =========================================================
        
        if type_paiement == 'avance':
            # Pour l'avance : unité doit être libre ou réservée
            if unite.statut not in ['libre', 'reserve']:
                raise serializers.ValidationError("Cette unité n'est pas disponible pour un paiement d'avance.")
            
            # Vérifier qu'il n'y a pas déjà un paiement en attente
            if Paiement.objects.filter(
                unite=unite, 
                locataire=user, 
                statut='en_attente'
            ).exists():
                raise serializers.ValidationError("Vous avez déjà un paiement en attente pour cette unité.")
        
        elif type_paiement == 'loyer':
            # Pour le loyer : vérifier que le locataire est bien le locataire actuel de l'unité
            locataire_actuel = Locataire.objects.filter(
                unite=unite,
                utilisateur=user,
                est_actif=True
            ).exists()
            
            if not locataire_actuel:
                raise serializers.ValidationError(
                    "Vous n'êtes pas le locataire de cette unité. Vous ne pouvez pas payer le loyer."
                )
            
            # Vérifier qu'il n'y a pas déjà un paiement de loyer pour la période
            if Paiement.objects.filter(
                unite=unite,
                locataire=user,
                type_paiement='loyer',
                statut='valide',
                periode_debut=attrs.get('periode_debut'),
                periode_fin=attrs.get('periode_fin')
            ).exists():
                raise serializers.ValidationError("Vous avez déjà payé le loyer pour cette période.")

        return attrs

    def create(self, validated_data):
        request = self.context.get('request')
        user = request.user
        unite = validated_data.pop('unite')
        mode_paiement = validated_data.get('mode_paiement')

        # Récupérer la demande stockée dans la validation
        demande = validated_data.pop('_demande', None)

        # ⚠️ Supprimer la clé 'demande' (l'ID) si elle existe encore
        validated_data.pop('demande', None)   # ← ESSENTIEL pour éviter le doublon

        # Déterminer le statut initial
        # Avec Fedapay, on met toujours 'en_attente' et le webhook le passera à 'valide'
        statut = 'en_attente'  # Changé pour Fedapay : on attend la confirmation webhook

        paiement = Paiement.objects.create(
            locataire=user,
            proprietaire=unite.proprietaire,
            unite=unite,
            demande=demande,
            statut=statut,
            **validated_data
        )

        # Le reçu sera généré après confirmation webhook ou validation manuelle
        return paiement
    
class RecuSerializer(serializers.ModelSerializer):
    """Sérialiseur pour les reçus de paiement"""
    class Meta:
        model = Recu
        fields = [
            'id', 'paiement', 'numero_recu', 'contenu',
            'fichier_pdf', 'date_generation', 'nombre_telechargements'
        ]
        read_only_fields = ['numero_recu', 'contenu', 'date_generation', 'nombre_telechargements']


class RecuRetraitSerializer(serializers.ModelSerializer):
    proprietaire_nom = serializers.CharField(source='proprietaire.get_full_name', read_only=True)

    class Meta:
        model = RecuRetrait
        fields = [
            'id', 'proprietaire', 'proprietaire_nom', 'montant',
            'telephone', 'operateur', 'reference', 'date_generation', 'fichier_pdf'
        ]


# Ajouter après les sérialiseurs existants

class DemandeRemboursementSerializer(serializers.ModelSerializer):
    locataire_nom = serializers.CharField(source='locataire.get_full_name', read_only=True)
    proprietaire_nom = serializers.CharField(source='proprietaire.get_full_name', read_only=True)
    paiement_info = serializers.SerializerMethodField()

    class Meta:
        model = DemandeRemboursement
        fields = [
            'id', 'locataire', 'locataire_nom', 'proprietaire', 'proprietaire_nom',
            'paiement', 'paiement_info', 'message', 'montant_demande',
            'montant_approuve', 'statut', 'date_demande', 'date_traitement'
        ]
        read_only_fields = ['statut', 'date_demande', 'date_traitement']

    def get_paiement_info(self, obj):
        p = obj.paiement
        return {
            'montant': p.montant,
            'date_paiement': p.date_paiement,
            'mode_paiement': p.get_mode_paiement_display(),
            'unite': p.unite.nom,
            'locataire': p.locataire.get_full_name(),
            'proprietaire': p.proprietaire.get_full_name(),
            'periode': f"{p.periode_debut} au {p.periode_fin}"
        }


class DemandeRemboursementCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = DemandeRemboursement
        fields = ['paiement', 'message']

    def validate(self, attrs):
        user = self.context['request'].user
        paiement = attrs['paiement']

        # Vérifier que le paiement appartient au locataire
        if paiement.locataire != user:
            raise serializers.ValidationError("Ce paiement ne vous appartient pas.")

        # Vérifier que c'est un paiement d'avance
        if paiement.type_paiement != 'avance':
            raise serializers.ValidationError("Seuls les paiements d'avance peuvent être remboursés.")

        # Vérifier qu'il n'y a pas déjà une demande en attente
        if DemandeRemboursement.objects.filter(paiement=paiement, statut='en_attente').exists():
            raise serializers.ValidationError("Une demande de remboursement est déjà en attente pour ce paiement.")

        return attrs


class RemboursementSerializer(serializers.ModelSerializer):
    locataire_nom = serializers.CharField(source='demande.locataire.get_full_name', read_only=True)
    proprietaire_nom = serializers.CharField(source='demande.proprietaire.get_full_name', read_only=True)

    class Meta:
        model = Remboursement
        fields = ['id', 'demande', 'montant', 'date_remboursement', 'reference', 'statut', 'fichier_pdf']