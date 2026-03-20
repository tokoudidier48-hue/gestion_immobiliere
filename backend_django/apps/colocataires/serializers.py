from rest_framework import serializers
from .models import RechercheColocataire, CandidatureColocataire

class RechercheColocataireSerializer(serializers.ModelSerializer):
    locataire_nom = serializers.CharField(source='locataire.get_full_name', read_only=True)
    unite_nom = serializers.CharField(source='unite.nom', read_only=True)
    
    class Meta:
        model = RechercheColocataire
        fields = [
            'id', 'locataire', 'locataire_nom', 'unite', 'unite_nom',
            'filiere', 'ville', 'religion', 'telephone', 'description',
            'est_active', 'date_creation', 'date_modification'
        ]
        read_only_fields = ['locataire', 'date_creation', 'date_modification']


class RechercheColocataireCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = RechercheColocataire
        fields = ['unite', 'filiere', 'ville', 'religion', 'telephone', 'description']
    
    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        if user.role != 'locataire':
            raise serializers.ValidationError("Seuls les locataires peuvent lancer une recherche de colocataire.")
        
        unite = attrs['unite']
        if unite.statut != 'libre':
            raise serializers.ValidationError("Cette unité n'est pas disponible.")
        
        # Vérifier si le locataire a déjà une recherche active pour cette unité
        if RechercheColocataire.objects.filter(locataire=user, unite=unite, est_active=True).exists():
            raise serializers.ValidationError("Vous avez déjà une recherche active pour cette unité.")
        
        return attrs
    
    def create(self, validated_data):
        request = self.context.get('request')
        user = request.user
        recherche = RechercheColocataire.objects.create(
            locataire=user,
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
            'est_acceptee', 'date_candidature', 'date_reponse'
        ]
        read_only_fields = ['candidat', 'date_candidature', 'date_reponse', 'est_acceptee']
    
    def get_recherche_info(self, obj):
        return {
            'id': obj.recherche.id,
            'locataire': obj.recherche.locataire.get_full_name(),
            'unite': obj.recherche.unite.nom,
            'filiere': obj.recherche.filiere,
            'ville': obj.recherche.ville
        }


class CandidatureColocataireCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = CandidatureColocataire
        fields = ['recherche', 'filiere', 'ville', 'religion', 'telephone', 'description']
    
    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        if user.role != 'locataire':
            raise serializers.ValidationError("Seuls les locataires peuvent postuler.")
        
        recherche = attrs['recherche']
        if not recherche.est_active:
            raise serializers.ValidationError("Cette recherche n'est plus active.")
        
        # Vérifier que le candidat n'est pas le locataire qui a lancé la recherche
        if recherche.locataire == user:
            raise serializers.ValidationError("Vous ne pouvez pas postuler à votre propre annonce.")
        
        # Vérifier si le candidat a déjà postulé
        if CandidatureColocataire.objects.filter(recherche=recherche, candidat=user).exists():
            raise serializers.ValidationError("Vous avez déjà postulé à cette annonce.")
        
        return attrs
    
    def create(self, validated_data):
        request = self.context.get('request')
        user = request.user
        candidature = CandidatureColocataire.objects.create(
            candidat=user,
            **validated_data
        )
        return candidature