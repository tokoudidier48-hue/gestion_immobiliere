from django.apps import AppConfig

class MessagerieConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'messagerie'
    verbose_name = 'Messagerie'
    
    def ready(self):
        # Importez les signaux pour qu'ils soient enregistrés
        import messagerie.signals