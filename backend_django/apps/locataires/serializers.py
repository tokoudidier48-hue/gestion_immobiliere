from rest_framework import serializers
from .models import Locataire
from comptes.serializers import UtilisateurSerializer

class LocataireSerializer(serializers.ModelSerializer):
    nom = serializers.CharField(source='utilisateur.last_name', read_only=True)
    prenom = serializers.CharField(source='utilisateur.first_name', read_only=True)
    email = serializers.EmailField(source='utilisateur.email', read_only=True)
    telephone = serializers.CharField(source='utilisateur.telephone', read_only=True)
    unite_nom = serializers.CharField(source='unite.nom', read_only=True)
    propriete_nom = serializers.CharField(source='propriete.nom', read_only=True)
    
    class Meta:
        model = Locataire
        fields = [
            'id', 'utilisateur', 'nom', 'prenom', 'email', 'telephone',
            'unite', 'unite_nom', 'propriete', 'propriete_nom',
            'date_entree', 'mode_paiement', 'date_creation'
        ]
        read_only_fields = ['date_creation']


class LocataireCreateUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Locataire
        fields = ['utilisateur', 'unite', 'propriete', 'date_entree', 'mode_paiement']
    
    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        if user.role != 'proprietaire':
            raise serializers.ValidationError("Seuls les propriétaires peuvent gérer les locataires.")
        
        # Vérifier que l'utilisateur assigné est bien un locataire
        utilisateur = attrs.get('utilisateur')
        if utilisateur and utilisateur.role != 'locataire':
            raise serializers.ValidationError("L'utilisateur sélectionné n'est pas un locataire.")
        
        # Vérifier que l'unité appartient bien au propriétaire connecté
        unite = attrs.get('unite')
        if unite and unite.proprietaire != user:
            raise serializers.ValidationError("Cette unité ne vous appartient pas.")
        
        # Vérifier que la propriété appartient bien au propriétaire connecté
        propriete = attrs.get('propriete')
        if propriete and propriete.proprietaire != user:
            raise serialisazers.ValidationError("Cette propriété ne vous appartient pas.")
        
        return attrs