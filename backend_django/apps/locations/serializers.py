from rest_framework import serializers
from .models import DemandeUnite

class DemandeUniteSerializer(serializers.ModelSerializer):
    locataire_nom = serializers.CharField(source='locataire.get_full_name', read_only=True)
    proprietaire_nom = serializers.CharField(source='proprietaire.get_full_name', read_only=True)
    unite_nom = serializers.CharField(source='unite.nom', read_only=True)
    unite_type = serializers.CharField(source='unite.get_type_unite_display', read_only=True)
    unite_loyer = serializers.DecimalField(source='unite.loyer', max_digits=10, decimal_places=0, read_only=True)

    class Meta:
        model = DemandeUnite
        fields = [
            'id', 'locataire', 'locataire_nom', 'proprietaire', 'proprietaire_nom',
            'unite', 'unite_nom', 'unite_type', 'unite_loyer', 'message',
            'statut', 'date_demande', 'date_reponse'
        ]
        read_only_fields = ['locataire', 'proprietaire', 'statut', 'date_demande', 'date_reponse']


class DemandeUniteCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = DemandeUnite
        fields = ['unite', 'message']

    def validate_unite(self, value):
        if value.statut != 'libre':
            raise serializers.ValidationError("Cette unité n'est pas disponible.")
        return value

    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        unite = attrs['unite']

        if user.role != 'locataire':
            raise serializers.ValidationError("Seuls les locataires peuvent faire une demande.")

        if DemandeUnite.objects.filter(locataire=user, unite=unite, statut='en_attente').exists():
            raise serializers.ValidationError("Vous avez déjà une demande en attente pour cette unité.")

        if unite.proprietaire.role != 'proprietaire':
            raise serializers.ValidationError("Le propriétaire de l'unité n'est pas valide.")

        return attrs

    def create(self, validated_data):
        request = self.context.get('request')
        user = request.user
        unite = validated_data['unite']
        demande = DemandeUnite.objects.create(
            locataire=user,
            proprietaire=unite.proprietaire,
            unite=unite,
            message=validated_data.get('message', '')
        )
        return demande