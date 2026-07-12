# apps/colocataires/serializers.py

from rest_framework import serializers
from django.utils import timezone
from datetime import timedelta
from .models import RechercheColocataire, CandidatureColocataire
from unites.models import Unite

# ⭐ CONSTANTE POUR LA LIMITE DE RECHERCHES ACTIVES
MAX_RECHERCHES_ACTIVES = 3


class RechercheColocataireSerializer(serializers.ModelSerializer):
    locataire_nom = serializers.CharField(source='locataire.get_full_name', read_only=True)
    unite_nom = serializers.CharField(source='unite.nom', read_only=True)
    
    # ⭐ Nouveaux champs pour Flutter
    nb_candidats_actifs = serializers.SerializerMethodField()
    total_occupants_potentiels = serializers.SerializerMethodField()
    
    class Meta:
        model = RechercheColocataire
        fields = [
            'id', 'locataire', 'locataire_nom', 'unite', 'unite_nom',
            'filiere', 'ville', 'religion', 'telephone', 'description',
            'statut', 'date_creation', 'date_modification', 'date_expiration',
            'nb_candidats_actifs', 'total_occupants_potentiels'
        ]
        read_only_fields = ['locataire', 'date_creation', 'date_modification', 'date_expiration', 'statut']

    def get_nb_candidats_actifs(self, obj):
        """Compte les candidatures en attente ou acceptées pour cette annonce précise"""
        return obj.candidatures.filter(statut__in=['en_attente', 'acceptee']).count()

    def get_total_occupants_potentiels(self, obj):
        """1 (le créateur de l'annonce) + le nombre de candidats actifs"""
        return 1 + self.get_nb_candidats_actifs(obj)


class RechercheColocataireCreateSerializer(serializers.ModelSerializer):
    # Accepter unite_id (recommandé) ou unite (pour compatibilité)
    unite_id = serializers.IntegerField(write_only=True, required=False)
    unite = serializers.PrimaryKeyRelatedField(
        queryset=Unite.objects.all(),
        write_only=True,
        required=False
    )
    
    class Meta:
        model = RechercheColocataire
        fields = ['unite_id', 'unite', 'filiere', 'ville', 'religion', 'telephone', 'description']
    
    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        
        # Vérifier que seul un locataire peut lancer une recherche
        if user.role != 'locataire':
            raise serializers.ValidationError("Seuls les locataires peuvent lancer une recherche de colocataire.")
        
        # Récupérer l'unité (soit depuis unite_id, soit depuis unite)
        unite = None
        if 'unite_id' in attrs and attrs['unite_id']:
            try:
                unite = Unite.objects.get(id=attrs['unite_id'])
            except Unite.DoesNotExist:
                raise serializers.ValidationError({"unite_id": "Unité non trouvée."})
        elif 'unite' in attrs and attrs['unite']:
            unite = attrs['unite']
        else:
            raise serializers.ValidationError({"unite": "L'unité est requise."})
        
        # Vérifier que l'unité est disponible
        if unite.statut != 'libre':
            raise serializers.ValidationError({"unite": "Cette unité n'est pas disponible pour une recherche de colocataire."})
        
        # Vérifier la limite de recherches actives
        active_count = RechercheColocataire.objects.filter(
            locataire=user,
            statut='active'
        ).count()
        
        if active_count >= MAX_RECHERCHES_ACTIVES:
            raise serializers.ValidationError(
                f"Vous avez atteint la limite maximale de {MAX_RECHERCHES_ACTIVES} recherches actives."
            )
        
        # Vérifier qu'il n'y a pas déjà une recherche active pour cette unité
        if RechercheColocataire.objects.filter(
            locataire=user, 
            unite=unite, 
            statut='active'
        ).exists():
            raise serializers.ValidationError("Vous avez déjà une recherche active pour cette unité.")
        
        # Stocker l'unité pour la création
        attrs['_unite'] = unite
        return attrs
    
    def create(self, validated_data):
        request = self.context.get('request')
        user = request.user
        
        # Récupérer l'unité
        unite = validated_data.pop('_unite')
        
        # Nettoyer les champs temporaires
        validated_data.pop('unite_id', None)
        validated_data.pop('unite', None)
        
        date_expiration = timezone.now() + timedelta(days=15)
        
        recherche = RechercheColocataire.objects.create(
            locataire=user,
            unite=unite,
            statut='active',
            date_expiration=date_expiration,
            **validated_data
        )
        return recherche


class CandidatureColocataireSerializer(serializers.ModelSerializer):
    candidat_nom = serializers.CharField(source='candidat.get_full_name', read_only=True)
    recherche_info = serializers.SerializerMethodField()
    
    class Meta:
        model = CandidatureColocataire
        fields = [
            'id', 'recherche', 'recherche_info', 'candidat', 'candidat_nom',
            'filiere', 'ville', 'religion', 'telephone', 'description',
            'statut', 'date_candidature', 'date_reponse'
        ]
        read_only_fields = ['candidat', 'date_candidature', 'date_reponse', 'statut']
    
    def get_recherche_info(self, obj):
        return {
            'id': obj.recherche.id,
            'locataire': obj.recherche.locataire.get_full_name(),
            'unite': obj.recherche.unite.nom,
            'filiere': obj.recherche.filiere,
            'ville': obj.recherche.ville
        }


class CandidatureColocataireCreateSerializer(serializers.ModelSerializer):
    # Accepter recherche_id (recommandé) ou recherche (pour compatibilité)
    recherche_id = serializers.IntegerField(write_only=True, required=False)
    recherche = serializers.PrimaryKeyRelatedField(
        queryset=RechercheColocataire.objects.all(),
        write_only=True,
        required=False
    )
    
    class Meta:
        model = CandidatureColocataire
        fields = ['recherche_id', 'recherche', 'filiere', 'ville', 'religion', 'telephone', 'description']
    
    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        
        if user.role != 'locataire':
            raise serializers.ValidationError("Seuls les locataires peuvent postuler.")
        
        # Récupérer la recherche (soit depuis recherche_id, soit depuis recherche)
        recherche_obj = None
        if 'recherche_id' in attrs and attrs['recherche_id']:
            try:
                recherche_obj = RechercheColocataire.objects.get(id=attrs['recherche_id'])
            except RechercheColocataire.DoesNotExist:
                raise serializers.ValidationError({"recherche_id": "Recherche non trouvée."})
        elif 'recherche' in attrs and attrs['recherche']:
            recherche_obj = attrs['recherche']
        else:
            raise serializers.ValidationError({"recherche": "La recherche est requise."})
        
        # Vérifier que la recherche est active
        if not recherche_obj.est_active():
            raise serializers.ValidationError("Cette recherche n'est plus active.")
        
        # Vérifier que le candidat n'est pas le créateur de l'annonce
        if recherche_obj.locataire == user:
            raise serializers.ValidationError("Vous ne pouvez pas postuler à votre propre annonce.")
        
        # Vérifier qu'il n'y a pas déjà une candidature
        if CandidatureColocataire.objects.filter(recherche=recherche_obj, candidat=user).exists():
            raise serializers.ValidationError("Vous avez déjà postulé à cette annonce.")
        
        # Stocker la recherche pour la création
        attrs['_recherche'] = recherche_obj
        return attrs
    
    def create(self, validated_data):
        request = self.context.get('request')
        user = request.user
        
        # Récupérer la recherche
        recherche_obj = validated_data.pop('_recherche')
        
        # Nettoyer les champs temporaires
        validated_data.pop('recherche_id', None)
        validated_data.pop('recherche', None)
        
        candidature = CandidatureColocataire.objects.create(
            recherche=recherche_obj,
            candidat=user,
            statut='en_attente',
            **validated_data
        )
        return candidature