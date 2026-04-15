from rest_framework import serializers
from .models import Paiement, Recu

class PaiementSerializer(serializers.ModelSerializer):
    locataire_nom = serializers.CharField(source='locataire.get_full_name', read_only=True)
    proprietaire_nom = serializers.CharField(source='proprietaire.get_full_name', read_only=True)
    unite_nom = serializers.CharField(source='unite.nom', read_only=True)

    class Meta:
        model = Paiement
        fields = [
            'id', 'locataire', 'locataire_nom', 'proprietaire', 'proprietaire_nom',
            'unite', 'unite_nom', 'demande', 'type_paiement', 'mode_paiement',
            'montant', 'numero_paiement', 'statut', 'periode_debut', 'periode_fin',
            'date_paiement', 'date_confirmation'
        ]
        read_only_fields = ['statut', 'date_paiement', 'date_confirmation']


class PaiementCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Paiement
        fields = [
            'unite', 'type_paiement', 'mode_paiement', 'montant',
            'numero_paiement', 'periode_debut', 'periode_fin'
        ]

    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        if user.role != 'locataire':
            raise serializers.ValidationError("Seuls les locataires peuvent effectuer un paiement.")

        unite = attrs['unite']
        if unite.statut != 'occupe':
            raise serializers.ValidationError("Cette unité n'est pas actuellement louée.")

        return attrs

    def create(self, validated_data):
        request = self.context.get('request')
        user = request.user
        # On retire 'unite' du dictionnaire pour éviter le doublon
        unite = validated_data.pop('unite')
        paiement = Paiement.objects.create(
            locataire=user,
            proprietaire=unite.proprietaire,
            unite=unite,
            **validated_data
        )
        # Confirmer le paiement et générer le reçu
        paiement.confirmer()
        return paiement


class RecuSerializer(serializers.ModelSerializer):
    class Meta:
        model = Recu
        fields = [
            'id', 'paiement', 'numero_recu', 'contenu',
            'fichier_pdf', 'date_generation', 'nombre_telechargements'
        ]
        read_only_fields = ['numero_recu', 'contenu', 'date_generation', 'nombre_telechargements']