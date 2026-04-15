from rest_framework import serializers
from .models import Propriete

class ProprieteSerializer(serializers.ModelSerializer):
    proprietaire_nom = serializers.CharField(source='proprietaire.get_full_name', read_only=True)

    class Meta:
        model = Propriete
        fields = ['id', 'nom', 'proprietaire', 'proprietaire_nom', 'date_creation']
        read_only_fields = ['date_creation', 'proprietaire']

    def validate_nom(self, value):
        """
        Vérifie que le nom de la propriété est unique globalement.
        """
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            # En création
            if not self.instance:
                if Propriete.objects.filter(nom=value).exists():
                    raise serializers.ValidationError(
                        "Ce nom de propriété est déjà utilisé par un autre propriétaire. Veuillez en choisir un autre."
                    )
            else:
                # En modification, on exclut l'instance courante
                if Propriete.objects.filter(nom=value).exclude(pk=self.instance.pk).exists():
                    raise serializers.ValidationError(
                        "Ce nom de propriété est déjà utilisé par un autre propriétaire. Veuillez en choisir un autre."
                    )
        return value

class ProprieteDetailSerializer(ProprieteSerializer):
    unites = serializers.StringRelatedField(many=True, read_only=True)

    class Meta(ProprieteSerializer.Meta):
        fields = ProprieteSerializer.Meta.fields + ['unites']