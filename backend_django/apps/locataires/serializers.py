from rest_framework import serializers
from .models import Locataire
from comptes.serializers import UtilisateurSerializer

class LocataireSerializer(serializers.ModelSerializer):
    nom = serializers.CharField(source='utilisateur.last_name', read_only=True)
    prenom = serializers.CharField(source='utilisateur.first_name', read_only=True)
    email = serializers.EmailField(source='utilisateur.email', read_only=True)
    telephone = serializers.CharField(source='utilisateur.telephone', read_only=True)
    unite_nom = serializers.CharField(source='unite.nom', read_only=True, allow_null=True)
    propriete_nom = serializers.CharField(source='propriete.nom', read_only=True)
    
    class Meta:
        model = Locataire
        fields = [
            'id', 'utilisateur', 'nom', 'prenom', 'email', 'telephone',
            'unite', 'unite_nom', 'propriete', 'propriete_nom',
            'date_entree', 'mode_paiement', 'est_actif', 'date_creation', 'date_modification'
        ]
        read_only_fields = ['date_creation', 'date_modification']


class LocataireCreateUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Locataire
        fields = ['utilisateur', 'propriete', 'unite', 'date_entree', 'mode_paiement']
    
    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        
        # Vérifier que l'utilisateur est un propriétaire
        if user.role != 'proprietaire':
            raise serializers.ValidationError("Seuls les propriétaires peuvent gérer les locataires.")
        
        # Vérifier que l'utilisateur assigné est bien un locataire
        utilisateur = attrs.get('utilisateur')
        if utilisateur and utilisateur.role != 'locataire':
            raise serializers.ValidationError("L'utilisateur sélectionné n'est pas un locataire.")
        
        # ⭐ Vérifier que la propriété appartient bien au propriétaire connecté ⭐
        propriete = attrs.get('propriete')
        if propriete and propriete.proprietaire != user:
            raise serializers.ValidationError("Cette propriété ne vous appartient pas.")
        
        # Vérifier que l'unité (si fournie) appartient bien à la propriété
        unite = attrs.get('unite')
        if unite:
            # Vérifier que l'unité appartient au propriétaire
            if unite.proprietaire != user:
                raise serializers.ValidationError("Cette unité ne vous appartient pas.")
            
            # ⭐ Vérifier que l'unité appartient bien à la propriété sélectionnée ⭐
            if unite.propriete != propriete:
                raise serializers.ValidationError("Cette unité n'appartient pas à la propriété sélectionnée.")
        
        # ⭐ Vérifier que le locataire n'est pas déjà dans cette propriété ⭐
        if Locataire.objects.filter(
            utilisateur=utilisateur, 
            propriete=propriete,
            est_actif=True
        ).exists():
            raise serializers.ValidationError("Ce locataire est déjà enregistré dans cette propriété.")
        
        return attrs


class LocataireUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Locataire
        fields = ['unite', 'date_entree', 'mode_paiement', 'est_actif']
    
    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        
        if user.role != 'proprietaire':
            raise serializers.ValidationError("Seuls les propriétaires peuvent modifier les locataires.")
        
        # Vérifier que l'unité appartient au propriétaire
        unite = attrs.get('unite')
        if unite and unite.proprietaire != user:
            raise serializers.ValidationError("Cette unité ne vous appartient pas.")
        
        return attrs