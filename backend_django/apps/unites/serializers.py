from rest_framework import serializers
from .models import Unite, PhotoUnite

class PhotoUniteSerializer(serializers.ModelSerializer):
    class Meta:
        model = PhotoUnite
        fields = ['id', 'image', 'est_principale', 'ordre']

class UniteSerializer(serializers.ModelSerializer):
    proprietaire_nom = serializers.CharField(source='proprietaire.get_full_name', read_only=True)
    propriete_nom = serializers.CharField(source='propriete.nom', read_only=True)
    photos = PhotoUniteSerializer(many=True, read_only=True)
    total_entree = serializers.SerializerMethodField()

    class Meta:
        model = Unite
        fields = [
            'id', 'nom', 'type_unite', 'description', 'adresse', 'ville',
            'type_douche', 'prepaye', 'garage', 'loyer', 'nombre_avances',
            'type_caution', 'prix_caution', 'contact_proprietaire',
            'statut', 'proprietaire', 'proprietaire_nom', 'propriete',
            'propriete_nom', 'photos', 'total_entree',
            'date_creation', 'date_modification'
        ]
        read_only_fields = ['date_creation', 'date_modification', 'proprietaire']

    def get_total_entree(self, obj):
        return obj.total_entree()


class UniteCreateUpdateSerializer(serializers.ModelSerializer):
    photos = serializers.ListField(
        child=serializers.ImageField(),
        write_only=True,
        required=False
    )

    class Meta:
        model = Unite
        fields = '__all__'
        read_only_fields = ['date_creation', 'date_modification', 'proprietaire']

    def create(self, validated_data):
        photos_data = validated_data.pop('photos', [])
        unite = Unite.objects.create(**validated_data)

        for index, image in enumerate(photos_data):
            PhotoUnite.objects.create(
                unite=unite,
                image=image,
                est_principale=(index == 0),
                ordre=index
            )
        return unite

    def update(self, instance, validated_data):
        photos_data = validated_data.pop('photos', [])
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        if photos_data:
            instance.photos.all().delete()
            for index, image in enumerate(photos_data):
                PhotoUnite.objects.create(
                    unite=instance,
                    image=image,
                    est_principale=(index == 0),
                    ordre=index
                )
        return instance