from django.apps import AppConfig

class LocatairesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'locataires'
    verbose_name = 'Gestion locataires'

    def ready(self):
        # ⭐ Importer les signaux pour qu'ils soient actifs ⭐
        import locataires.signals