from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.http import HttpResponse
from .models import Paiement, Recu, RecuRetrait, TransactionJournal, Remboursement, DemandeRemboursement
from .serializers import PaiementSerializer, PaiementCreateSerializer, RecuSerializer, DemandeRemboursementCreateSerializer, DemandeRemboursementSerializer
from notifications.models import Notification
from notifications.fcm_service import notify_user
from django.utils import timezone
from locataires.models import Locataire
from locations.models import DemandeUnite
from django.conf import settings
import os
import uuid
from django.http import FileResponse
from decimal import Decimal
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from django.http import HttpResponse
from io import BytesIO
from reportlab.lib import colors

from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from .fedapay_service import FedaPayService
from django.views.decorators.csrf import csrf_exempt
import json

from django.views.decorators.csrf import csrf_exempt
import logging
from .serializers import PaiementCreateSerializer
logger = logging.getLogger(__name__)

class PaiementViewSet(viewsets.ModelViewSet):
    queryset = Paiement.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'locataire':
            return Paiement.objects.filter(locataire=user)
        elif user.role == 'proprietaire':
            return Paiement.objects.filter(proprietaire=user)
        return Paiement.objects.none()

    def get_serializer_class(self):
        if self.action == 'create':
            return PaiementCreateSerializer
        return PaiementSerializer
    
    # apps/paiements/views.py - à l'intérieur de la classe PaiementViewSet

    def _annuler_autres_demandes(self, unite, locataire_exclu):
        """Annule toutes les demandes en attente pour une unité, sauf celle du locataire exclu."""
        from locations.models import DemandeUnite
        from notifications.models import Notification
        from notifications.fcm_service import notify_user

        autres_demandes = DemandeUnite.objects.filter(
            unite=unite,
            statut='en_attente'
        ).exclude(locataire=locataire_exclu)

        for demande in autres_demandes:
            demande.annuler()  # Cette méthode existe déjà dans DemandeUnite
            # Notification en base
            Notification.objects.create(
                destinataire=demande.locataire,
                type='demande',
                titre='Demande annulée',
                message=f"Votre demande pour l'unité {unite.nom} a été annulée car un autre locataire a déjà effectué le paiement.",
                lien=f'/demandes/{demande.id}'
            )
            # Notification push
            notify_user(
                demande.locataire,
                'Demande annulée',
                f"Votre demande pour {unite.nom} a été annulée car l'unité est déjà prise.",
                {'type': 'demande', 'demande_id': str(demande.id)}
            )

    def perform_create(self, serializer):
        paiement = serializer.save()
        unite = paiement.unite
        
        # ⭐ SI PAIEMENT EN LIGNE (MTN/MOOV/CELTIS) - VALIDER IMMÉDIATEMENT ⭐
        if paiement.mode_paiement != 'especes':
            # Valider le paiement
            paiement.statut = 'valide'
            paiement.save()
            
            # ⭐ OCCUPER L'UNITÉ APRÈS PAIEMENT VALIDÉ ⭐
            unite.statut = 'occupe'
            unite.locataire_actuel = paiement.locataire
            unite.date_debut_location = timezone.now()
            unite.save()

            # ⭐ NOUVEAU : Annuler les autres demandes en attente pour cette unité
            self._annuler_autres_demandes(unite, paiement.locataire)
            
            # ⭐ AJOUTER LE LOCATAIRE À LA PROPRIÉTÉ ⭐
            Locataire.objects.get_or_create(
                utilisateur=paiement.locataire,
                propriete=unite.propriete,
                defaults={
                    'unite': unite,
                    'date_entree': timezone.now().date(),
                    'mode_paiement': 'en_ligne',
                    'est_actif': True
                }
            )
            
            # Générer le reçu
            paiement.confirmer()
            
            # Notification push au propriétaire
            notify_user(
                unite.proprietaire,
                'Paiement reçu',
                f"{paiement.locataire.get_full_name()} a effectué un paiement de {paiement.montant} FCFA pour {unite.nom}.",
                {'type': 'paiement', 'paiement_id': str(paiement.id)}
            )
            
            # Notification push au locataire
            notify_user(
                paiement.locataire,
                'Paiement confirmé',
                f"Votre paiement du loyer de {paiement.montant} FCFA pour l'unité {unite.nom} a été effectué avec succès.",
                {'type': 'paiement', 'paiement_id': str(paiement.id)}
            )
        
        # ⭐ SI PAIEMENT EN ESPÈCES - GARDER EN ATTENTE ⭐
        else:
            # Notification au propriétaire qu'un paiement en espèces est en attente
            Notification.objects.create(
                destinataire=unite.proprietaire,
                type='paiement',
                titre='Paiement en espèces en attente',
                message=f"{paiement.locataire.get_full_name()} a déclaré un paiement de {paiement.montant} FCFA en espèces pour {unite.nom}. Veuillez valider.",
                lien=f'/paiements/{paiement.id}'
            )
            
            # Notification push au propriétaire
            notify_user(
                unite.proprietaire,
                'Paiement en espèces en attente',
                f"{paiement.locataire.get_full_name()} a déclaré un paiement de {paiement.montant} FCFA. À valider.",
                {'type': 'paiement', 'paiement_id': str(paiement.id)}
            )

    # ⭐ ENDPOINTS POUR PAIEMENTS EN ESPÈCES ⭐
    
    @action(detail=False, methods=['get'])
    def en_attente(self, request):
        """Récupère les paiements en espèces en attente (pour propriétaire)"""
        if request.user.role != 'proprietaire':
            return Response(
                {'error': 'Accès réservé aux propriétaires'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        paiements = Paiement.objects.filter(
            mode_paiement='especes',
            statut='en_attente',
            proprietaire=request.user
        )
        serializer = self.get_serializer(paiements, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def accepter(self, request, pk=None):
        """Accepte un paiement en espèces"""
        paiement = self.get_object()
        
        # Vérifier que l'utilisateur est le propriétaire
        if request.user.role != 'proprietaire' or paiement.proprietaire != request.user:
            return Response(
                {'error': 'Vous n\'êtes pas autorisé'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Vérifier que le paiement est en attente
        if paiement.statut != 'en_attente':
            return Response(
                {'error': 'Ce paiement n\'est plus en attente'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier que c'est un paiement en espèces
        if paiement.mode_paiement != 'especes':
            return Response(
                {'error': 'Cette action n\'est disponible que pour les paiements en espèces'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Valider le paiement
        paiement.statut = 'valide'
        paiement.save()
        
        # ⭐ OCCUPER L'UNITÉ APRÈS VALIDATION DU PAIEMENT ESPÈCES ⭐
        unite = paiement.unite
        unite.statut = 'occupe'
        unite.locataire_actuel = paiement.locataire
        unite.date_debut_location = timezone.now()
        unite.save()

        # ⭐ NOUVEAU : Annuler les autres demandes en attente pour cette unité
        self._annuler_autres_demandes(unite, paiement.locataire)
        
        # ⭐ AJOUTER LE LOCATAIRE À LA PROPRIÉTÉ - VÉRIFIER LA CRÉATION ⭐
        locataire_obj, created = Locataire.objects.get_or_create(
            utilisateur=paiement.locataire,
            propriete=unite.propriete,
            defaults={
                'unite': unite,
                'date_entree': timezone.now().date(),
                'mode_paiement': 'especes',
                'est_actif': True
            }
        )
        
        # ⭐ LOG POUR DÉBOGUER ⭐
        print(f"🔍 Locataire créé: {created}")
        print(f"🔍 Locataire ID: {locataire_obj.id}")
        print(f"🔍 Propriété: {unite.propriete.nom}")
        print(f"🔍 Montant: {paiement.montant} FCFA")
        
        # Générer le reçu
        paiement.confirmer()
        
        # Créer une notification dans la base de données
        Notification.objects.create(
            destinataire=paiement.locataire,
            type='paiement',
            titre='Paiement accepté',
            message=f"Votre paiement de {paiement.montant} FCFA a été accepté. L'unité {unite.nom} est maintenant à vous.",
            lien=f'/paiements/{paiement.id}'
        )
        
        # Envoyer notification push au locataire
        notify_user(
            paiement.locataire,
            'Paiement accepté',
            f'Votre paiement de {paiement.montant} FCFA a été accepté. L\'unité {unite.nom} est maintenant à vous.',
            {'type': 'paiement', 'paiement_id': str(paiement.id)}
        )
        
        # ⭐ RÉPONSE AVEC LE MONTANT ⭐
        return Response({
            'message': 'Paiement accepté avec succès',
            'statut': paiement.statut,
            'unite_statut': unite.statut,
            'montant': str(paiement.montant),
            'montant_int': int(paiement.montant),
            'locataire_cree': created,
            'locataire': {
                'id': locataire_obj.id,
                'nom': paiement.locataire.last_name,
                'prenom': paiement.locataire.first_name,
                'email': paiement.locataire.email,
                'telephone': paiement.locataire.telephone,
                'propriete_id': unite.propriete.id,
                'propriete_nom': unite.propriete.nom,
                'unite_id': unite.id,
                'unite_nom': unite.nom,
                'montant': str(paiement.montant),
                'date_entree': timezone.now().date().isoformat(),
                'est_actif': True
            }
        })

    @action(detail=True, methods=['post'])
    def refuser(self, request, pk=None):
        """Refuse un paiement en espèces"""
        paiement = self.get_object()
        
        # Vérifier que l'utilisateur est le propriétaire
        if request.user.role != 'proprietaire' or paiement.proprietaire != request.user:
            return Response(
                {'error': 'Vous n\'êtes pas autorisé'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Vérifier que le paiement est en attente
        if paiement.statut != 'en_attente':
            return Response(
                {'error': 'Ce paiement n\'est plus en attente'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier que c'est un paiement en espèces
        if paiement.mode_paiement != 'especes':
            return Response(
                {'error': 'Cette action n\'est disponible que pour les paiements en espèces'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Refuser le paiement
        paiement.statut = 'refuse'
        paiement.save()
        
        # Créer une notification dans la base de données
        Notification.objects.create(
            destinataire=paiement.locataire,
            type='paiement',
            titre='Paiement refusé',
            message=f"Votre paiement de {paiement.montant} FCFA a été refusé. Veuillez contacter le propriétaire.",
            lien=f'/paiements/{paiement.id}'
        )
        
        # Envoyer notification push au locataire
        notify_user(
            paiement.locataire,
            'Paiement refusé',
            f'Votre paiement de {paiement.montant} FCFA a été refusé',
            {'type': 'paiement', 'paiement_id': str(paiement.id)}
        )
        
        return Response({
            'message': 'Paiement refusé',
            'statut': paiement.statut
        })

    @action(detail=True, methods=['get'])
    def recu(self, request, pk=None):
        paiement = self.get_object()
        try:
            recu = paiement.recu
            recu.nombre_telechargements += 1
            recu.save()
            serializer = RecuSerializer(recu)
            return Response(serializer.data)
        except Recu.DoesNotExist:
            return Response({'error': 'Reçu non trouvé'}, status=status.HTTP_404_NOT_FOUND)
        
    @action(detail=True, methods=['post'], url_path='verifier-statut')
    def verifier_statut(self, request, pk=None):
        """Vérifie le statut d'un paiement auprès de FedaPay et met à jour en base si approuvé."""
        paiement = self.get_object()
        
        # Vérifier que l'utilisateur est le locataire ou le propriétaire
        user = request.user
        if paiement.locataire != user and paiement.proprietaire != user:
            return Response({'error': 'Accès non autorisé.'}, status=403)
        
        # Si déjà valide, retourner simplement le statut
        if paiement.statut == 'valide':
            return Response({'statut': paiement.statut, 'message': 'Paiement déjà confirmé.'})
        
        # Récupérer l'ID de transaction FedaPay
        fedapay_transaction_id = paiement.numero_paiement
        if not fedapay_transaction_id:
            return Response({'error': 'Aucune transaction FedaPay associée.'}, status=400)
        
        # Interroger FedaPay
        fedapay = FedaPayService()
        try:
            transaction_data = fedapay.verify_transaction(fedapay_transaction_id)
            # La réponse est sous la clé 'v1/transaction'
            transaction_obj = transaction_data.get('v1/transaction', {})
            status_fedapay = transaction_obj.get('status')
            
            if status_fedapay == 'approved' and paiement.statut != 'valide':
                # ⭐ Valider le paiement avec la même logique que le webhook
                _valider_paiement(paiement)
                return Response({
                    'statut': paiement.statut,
                    'message': 'Paiement confirmé avec succès.',
                    'paiement_id': paiement.id
                }, status=200)
            else:
                return Response({
                    'statut': paiement.statut,
                    'message': f'Statut actuel : {status_fedapay or paiement.statut}'
                }, status=200)
                
        except Exception as e:
            return Response({
                'error': f'Erreur lors de la vérification : {str(e)}'
            }, status=500)


class RecuViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Recu.objects.all()
    serializer_class = RecuSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'locataire':
            return Recu.objects.filter(paiement__locataire=user)
        elif user.role == 'proprietaire':
            return Recu.objects.filter(paiement__proprietaire=user)
        return Recu.objects.none()

    @action(detail=True, methods=['get', 'post'])
    def telecharger(self, request, pk=None):
        """Télécharge un reçu professionnel au format PDF (style facture)"""
        recu = self.get_object()
        paiement = recu.paiement

        # Vérification des droits
        user = request.user
        if user.role == 'locataire' and paiement.locataire != user:
            raise PermissionDenied("Vous n'êtes pas autorisé à télécharger ce reçu.")
        elif user.role == 'proprietaire' and paiement.proprietaire != user:
            raise PermissionDenied("Vous n'êtes pas autorisé à télécharger ce reçu.")

        recu.nombre_telechargements += 1
        recu.save()

        try:
            buffer = BytesIO()
            # Document avec marges réduites pour occuper tout l'espace
            doc = SimpleDocTemplate(
                buffer,
                pagesize=A4,
                topMargin=10*mm,
                bottomMargin=10*mm,
                leftMargin=15*mm,
                rightMargin=15*mm,
            )
            story = []

            # ----- Styles personnalisés -----
            styles = getSampleStyleSheet()
            bleu_fonce = colors.HexColor('#1A4D8C')
            bleu_clair = colors.HexColor('#E6F0FA')
            gris_fonce = colors.HexColor('#333333')
            gris_clair = colors.HexColor('#F5F5F5')
            blanc = colors.white

            # Titre principal
            titre_style = ParagraphStyle(
                name='TitrePrincipal',
                parent=styles['Title'],
                fontName='Helvetica-Bold',
                fontSize=28,
                textColor=bleu_fonce,
                alignment=TA_CENTER,
                spaceAfter=6,
            )
            sous_titre_style = ParagraphStyle(
                name='SousTitre',
                parent=styles['Normal'],
                fontName='Helvetica',
                fontSize=14,
                textColor=gris_fonce,
                alignment=TA_CENTER,
                spaceAfter=20,
            )

            # Styles pour les sections (en‑tête coloré)
            section_style = ParagraphStyle(
                name='Section',
                parent=styles['Normal'],
                fontName='Helvetica-Bold',
                fontSize=14,
                textColor=blanc,
                backColor=bleu_fonce,
                spaceAfter=6,
                spaceBefore=12,
                leftIndent=5,
                rightIndent=5,
            )

            # Style pour le texte normal
            texte_style = ParagraphStyle(
                name='Texte',
                parent=styles['Normal'],
                fontName='Helvetica',
                fontSize=11,
                textColor=gris_fonce,
                leading=14,
            )

            # Style pour les labels (gras)
            label_style = ParagraphStyle(
                name='Label',
                parent=texte_style,
                fontName='Helvetica-Bold',
                textColor=bleu_fonce,
            )

            # ----- Logo (optionnel) -----
            logo_path = os.path.join(settings.BASE_DIR, 'static', 'images', 'Logo.jpg')
            if os.path.exists(logo_path):
                story.append(Image(logo_path, width=55*mm, height=22*mm, hAlign='CENTER'))
                story.append(Spacer(1, 5*mm))

            story.append(Paragraph("LOYASMART", titre_style))
            story.append(Paragraph("Reçu de paiement", sous_titre_style))

            # ---- Informations générales (numéro, date) avec fond gris clair ----
            info_data = [
                [Paragraph("N° reçu :", label_style), Paragraph(recu.numero_recu, texte_style),
                Paragraph("Date :", label_style), Paragraph(recu.date_generation.strftime('%d/%m/%Y %H:%M'), texte_style)]
            ]
            info_table = Table(info_data, colWidths=[doc.width*0.2, doc.width*0.3, doc.width*0.2, doc.width*0.3])
            info_table.setStyle(TableStyle([
                ('BACKGROUND', (0,0), (-1,0), gris_clair),
                ('GRID', (0,0), (-1,0), 0.5, bleu_fonce),
                ('ALIGN', (0,0), (0,0), 'RIGHT'),
                ('ALIGN', (2,0), (2,0), 'RIGHT'),
                ('VALIGN', (0,0), (-1,0), 'MIDDLE'),
                ('PADDING', (0,0), (-1,0), 8),
            ]))
            story.append(info_table)
            story.append(Spacer(1, 8*mm))

            # ----- Fonction pour créer une section structurée (table à 2 colonnes) -----
            def ajouter_section(titre, champs):
                # Titre de section avec fond bleu
                story.append(Paragraph(titre, section_style))
                data = []
                for label, valeur in champs:
                    data.append([Paragraph(label, label_style), Paragraph(valeur, texte_style)])
                if data:
                    t = Table(data, colWidths=[doc.width*0.3, doc.width*0.7])
                    t.setStyle(TableStyle([
                        ('BACKGROUND', (0,0), (0,-1), gris_clair),
                        ('GRID', (0,0), (-1,-1), 0.2, bleu_fonce),
                        ('VALIGN', (0,0), (-1,-1), 'TOP'),
                        ('PADDING', (0,0), (-1,-1), 6),
                    ]))
                    story.append(t)
                    story.append(Spacer(1, 6*mm))

            # ---- Propriétaire ----
            proprio_champs = [
                ("Nom :", paiement.proprietaire.get_full_name()),
                ("Email :", paiement.proprietaire.email),
                ("Téléphone :", paiement.proprietaire.telephone or "Non renseigné"),
            ]
            ajouter_section("PROPRIÉTAIRE", proprio_champs)

            # ---- Locataire ----
            locataire_champs = [
                ("Nom :", paiement.locataire.get_full_name()),
                ("Email :", paiement.locataire.email),
                ("Téléphone :", paiement.locataire.telephone or "Non renseigné"),
            ]
            ajouter_section("LOCATAIRE", locataire_champs)

            # ---- Unité ----
            unite_champs = [
                ("Nom :", paiement.unite.nom),
                ("Adresse :", f"{paiement.unite.adresse}, {paiement.unite.ville}"),
            ]
            ajouter_section("UNITÉ", unite_champs)

            # ---- Détails du paiement ----
            paiement_champs = [
                ("Type :", paiement.get_type_paiement_display()),
                ("Montant :", f"{paiement.montant} FCFA"),
                ("Mode :", paiement.get_mode_paiement_display()),
                ("Période :", f"du {paiement.periode_debut} au {paiement.periode_fin}"),
                ("Numéro de transaction :", paiement.numero_paiement),
            ]
            ajouter_section("DÉTAILS DU PAIEMENT", paiement_champs)

            # ---- Pied de page (remerciements) ----
            story.append(Spacer(1, 15*mm))
            pied_style = ParagraphStyle(
                name='Pied',
                parent=texte_style,
                fontSize=9,
                textColor=gris_fonce,
                alignment=TA_CENTER,
            )
            story.append(Paragraph("Merci de votre confiance. Ce reçu est généré automatiquement.", pied_style))
            story.append(Paragraph("LoyaSmart - Gestion locative intelligente", pied_style))

            doc.build(story)
            buffer.seek(0)

            response = HttpResponse(buffer.getvalue(), content_type='application/pdf')
            response['Content-Disposition'] = f'inline; filename="recu_{recu.id}.pdf"'
            response['Content-Length'] = buffer.getbuffer().nbytes
            return response

        except Exception as e:
            print(f"❌ Erreur génération PDF: {e}")
            return Response(
                {'error': f'Erreur lors de la génération du PDF: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    @action(detail=True, methods=['get'], url_path='download')
    def download_pdf(self, request, pk=None):
        """Télécharge directement le PDF (alias pour compatibilité)"""
        return self.telecharger(request, pk)


class InitierPaiementView(APIView):
    """
    Vue pour initier un paiement via FedaPay.
    Crée une transaction FedaPay et retourne un token de paiement.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = PaiementCreateSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        paiement = serializer.save()

        fedapay = FedaPayService()
        try:
            # ⚠️ Utiliser l'URL ngrok pour les tests
            webhook_url = "https://eulah-unconsoling-elliott.ngrok-free.dev/api/paiements/webhook/"
            logger.info(f"🔗 Webhook URL: {webhook_url}")

            transaction_data = fedapay.create_transaction(
                amount=int(paiement.montant),
                description=f"Paiement pour {paiement.unite.nom} - {paiement.locataire.get_full_name()}",
                customer_email=paiement.locataire.email,
                customer_name=paiement.locataire.get_full_name(),
                callback_url=webhook_url
            )

            # Récupérer l'objet transaction
            transaction_obj = transaction_data.get('v1/transaction')
            if not transaction_obj:
                raise Exception("La transaction FedaPay n'a pas été créée correctement.")

            fedapay_transaction_id = transaction_obj.get('id')
            payment_token = transaction_obj.get('payment_token')
            payment_url = transaction_obj.get('payment_url')  # ⭐ NOUVEAU

            logger.info(f"✅ Transaction FedaPay créée: {fedapay_transaction_id}")

            paiement.numero_paiement = fedapay_transaction_id
            paiement.save()

            return Response({
                'message': 'Paiement initié avec succès',
                'payment_token': payment_token,
                'payment_url': payment_url,        # ⭐ AJOUTER CETTE LIGNE
                'transaction_id': fedapay_transaction_id,
                'paiement_id': paiement.id
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.exception("❌ Erreur lors de l'initiation du paiement")
            paiement.statut = 'echoue'
            paiement.save()
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _valider_paiement(paiement):
    """
    Valide un paiement :
      - Occupe l'unité
      - Annule les autres demandes
      - Ajoute le locataire à la propriété
      - Génère le reçu
      - Crédite le propriétaire (après commission de 3%)
      - Envoie les notifications
    """
    # ⭐ 1. Valider le paiement
    paiement.statut = 'valide'
    paiement.date_confirmation = timezone.now()
    paiement.save()

    unite = paiement.unite

    # ⭐ 2. Occuper l'unité
    unite.statut = 'occupe'
    unite.locataire_actuel = paiement.locataire
    unite.date_debut_location = timezone.now()
    unite.save()

    # ⭐ 3. Annuler les autres demandes pour cette unité
    PaiementViewSet()._annuler_autres_demandes(unite, paiement.locataire)

    # ⭐ 4. Ajouter le locataire à la propriété
    Locataire.objects.get_or_create(
        utilisateur=paiement.locataire,
        propriete=unite.propriete,
        defaults={
            'unite': unite,
            'date_entree': timezone.now().date(),
            'mode_paiement': 'en_ligne',
            'est_actif': True
        }
    )

    # ⭐ 5. Générer le reçu de paiement
    paiement.confirmer()

    # ⭐ 6. CRÉDITER LE PROPRIÉTAIRE (après commission de 3%)
    proprio = paiement.proprietaire
    montant_total = paiement.montant
    commission = montant_total * Decimal('0.03')      # 3% de commission
    montant_proprio = montant_total - commission      # Montant net pour le propriétaire

    # Ajouter au solde du propriétaire
    proprio.solde += montant_proprio
    proprio.save()

    # ⭐ 7. Journaliser la transaction (pour traçabilité)
    try:
        TransactionJournal.objects.create(
            proprietaire=proprio,
            locataire=paiement.locataire,
            unite=paiement.unite,
            type='credit',
            montant=montant_proprio,
            commission=commission,
            paiement=paiement
        )
    except NameError:
        # Si le modèle TransactionJournal n'existe pas encore, on logge simplement
        logger.warning("⚠️ TransactionJournal non défini – journalisation ignorée.")

    logger.info(
        f"💰 Propriétaire {proprio.id} crédité de {montant_proprio} FCFA. "
        f"Commission: {commission} FCFA."
    )

    # ⭐ 8. Notifications
    Notification.objects.create(
        destinataire=unite.proprietaire,
        type='paiement',
        titre='Paiement reçu',
        message=f"{paiement.locataire.get_full_name()} a effectué un paiement de {paiement.montant} FCFA pour {unite.nom}.",
        lien=f'/paiements/{paiement.id}'
    )
    notify_user(
        unite.proprietaire,
        'Paiement reçu',
        f"{paiement.locataire.get_full_name()} a effectué un paiement de {paiement.montant} FCFA pour {unite.nom}.",
        {'type': 'paiement', 'paiement_id': str(paiement.id)}
    )

    Notification.objects.create(
        destinataire=paiement.locataire,
        type='paiement',
        titre='Paiement confirmé',
        message=f"Votre paiement de {paiement.montant} FCFA pour l'unité {unite.nom} a été effectué avec succès.",
        lien=f'/paiements/{paiement.id}'
    )
    notify_user(
        paiement.locataire,
        'Paiement confirmé',
        f"Votre paiement de {paiement.montant} FCFA pour l'unité {unite.nom} a été effectué avec succès.",
        {'type': 'paiement', 'paiement_id': str(paiement.id)}
    )

    logger.info(f"✅ Paiement {paiement.id} validé et unité {unite.id} occupée.")
    return HttpResponse("Paiement validé avec succès.", status=200)


# ⭐ Webhook / Callback FedaPay (gère POST et GET)
@csrf_exempt
def webhook_fedapay(request):
    """
    Webhook et callback pour FedaPay.
    Accepte les requêtes POST (webhook) et GET (callback du navigateur).
    """
    # === Gestion du callback GET (redirection après paiement) ===
    if request.method == 'GET':
        status_param = request.GET.get('status')
        transaction_id = request.GET.get('id')
        logger.info(f"📨 Callback reçu: status={status_param}, transaction_id={transaction_id}")

        if status_param == 'approved':
            paiement = Paiement.objects.filter(numero_paiement=transaction_id).first()
            if paiement and paiement.statut != 'valide':
                return _valider_paiement(paiement)
            else:
                return HttpResponse("Paiement déjà traité ou introuvable.", status=200)
        else:
            return HttpResponse(f"Statut du paiement: {status_param}", status=200)

    # === Gestion du webhook POST (notification asynchrone) ===
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            event_type = data.get('type')
            logger.info(f"📨 Webhook reçu: {event_type}")

            if event_type == 'transaction.approved':
                transaction_data = data.get('data', {})
                transaction_id = transaction_data.get('id')
                paiement = Paiement.objects.filter(numero_paiement=transaction_id).first()

                if paiement and paiement.statut != 'valide':
                    return _valider_paiement(paiement)
                else:
                    logger.warning(f"⚠️ Paiement non trouvé ou déjà validé pour la transaction {transaction_id}")
                return HttpResponse(status=200)

            elif event_type == 'transaction.failed':
                transaction_data = data.get('data', {})
                transaction_id = transaction_data.get('id')
                paiement = Paiement.objects.filter(numero_paiement=transaction_id).first()
                if paiement and paiement.statut != 'valide':
                    paiement.statut = 'echoue'
                    paiement.save()
                    logger.info(f"❌ Paiement {paiement.id} marqué comme échoué")
                return HttpResponse(status=200)

            # Autres événements (non traités)
            logger.info(f"ℹ️ Événement non traité: {event_type}")
            return HttpResponse(status=200)

        except json.JSONDecodeError as e:
            logger.error(f"❌ JSON invalide reçu: {e}")
            return HttpResponse(status=400)
        except Exception as e:
            logger.exception("❌ Erreur webhook FedaPay")
            return HttpResponse(status=500)

    # Méthode non autorisée
    return HttpResponse(status=405)


class DemanderRetraitView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user

        if user.role != 'proprietaire':
            return Response({'error': 'Seuls les propriétaires peuvent demander un retrait.'}, status=403)

        montant = request.data.get('montant')
        telephone = request.data.get('telephone')
        operateur = request.data.get('operateur')

        if not montant or not telephone or not operateur:
            return Response({'error': 'Tous les champs sont requis.'}, status=400)

        try:
            montant = Decimal(montant)
        except:
            return Response({'error': 'Montant invalide.'}, status=400)

        if montant > user.solde:
            return Response({'error': 'Solde insuffisant.'}, status=400)

        fedapay = FedaPayService()
        try:
            payout_data = fedapay.create_payout(
                amount=int(montant),
                customer_email=user.email,
                customer_name=user.get_full_name(),
                phone_number=telephone,
                mode=operateur
            )

            # Déduire du solde
            user.solde -= montant
            user.save()

            # Générer un reçu de retrait
            recu_retrait = RecuRetrait.objects.create(
                proprietaire=user,
                montant=montant,
                telephone=telephone,
                operateur=operateur,
                reference=payout_data.get('id')
            )

            # ⭐ GÉNÉRER LE PDF AVANT DE RÉPONDRE ⭐
            recu_retrait.generer_pdf()

            return Response({
                'message': 'Retrait en cours de traitement.',
                'payout_id': payout_data.get('id'),
                'recu_id': recu_retrait.id
            }, status=200)

        except Exception as e:
            return Response({'error': str(e)}, status=500)
        

class RecuRetraitDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            recu = RecuRetrait.objects.get(id=pk)
        except RecuRetrait.DoesNotExist:
            return Response({'error': 'Reçu de retrait non trouvé.'}, status=404)

        # Vérifier que l'utilisateur est le propriétaire du reçu
        if recu.proprietaire != request.user:
            return Response({'error': 'Accès non autorisé.'}, status=403)

        # Construire la réponse manuellement (ou utiliser un sérialiseur)
        return Response({
            'id': recu.id,
            'proprietaire': recu.proprietaire.id,
            'proprietaire_nom': recu.proprietaire.get_full_name(),
            'montant': recu.montant,
            'telephone': recu.telephone,
            'operateur': recu.operateur,
            'reference': recu.reference,
            'date_generation': recu.date_generation,
            'fichier_pdf': recu.fichier_pdf.url if recu.fichier_pdf else None
        }, status=200)
    
class TelechargerRecuRetraitView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            recu = RecuRetrait.objects.get(id=pk)
        except RecuRetrait.DoesNotExist:
            return Response({'error': 'Reçu non trouvé.'}, status=404)

        # Vérifier que l'utilisateur est le propriétaire
        if recu.proprietaire != request.user:
            return Response({'error': 'Accès non autorisé.'}, status=403)

        # Vérifier que le fichier existe
        if not recu.fichier_pdf or not os.path.exists(recu.fichier_pdf.path):
            return Response({'error': 'Fichier PDF non disponible.'}, status=404)

        # Ouvrir et retourner le fichier
        response = FileResponse(
            open(recu.fichier_pdf.path, 'rb'),
            content_type='application/pdf'
        )
        response['Content-Disposition'] = f'attachment; filename="recu_retrait_{recu.id}.pdf"'
        return response
    
    # Ajouter après les vues existantes

class DemanderRemboursementView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if user.role != 'locataire':
            return Response({'error': 'Seuls les locataires peuvent demander un remboursement.'}, status=403)

        serializer = DemandeRemboursementCreateSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)

        # ⭐ Récupérer le paiement depuis les données validées
        paiement = serializer.validated_data['paiement']

        # ⭐ Créer la demande avec les bonnes valeurs
        demande = serializer.save(
            locataire=user,
            proprietaire=paiement.proprietaire,
            montant_demande=paiement.montant
        )

        # Notification au propriétaire
        Notification.objects.create(
            destinataire=demande.proprietaire,
            type='demande_remboursement',
            titre='Nouvelle demande de remboursement',
            message=f"{demande.locataire.get_full_name()} demande le remboursement de {demande.montant_demande} FCFA pour l'unité {demande.paiement.unite.nom}.",
            lien=f'/demandes-remboursement/{demande.id}'
        )
        notify_user(
            demande.proprietaire,
            'Nouvelle demande de remboursement',
            f"{demande.locataire.get_full_name()} demande le remboursement de {demande.montant_demande} FCFA.",
            {'type': 'demande_remboursement', 'demande_id': str(demande.id)}
        )

        return Response(DemandeRemboursementSerializer(demande).data, status=201)


class TraiterDemandeRemboursementView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        if user.role != 'proprietaire':
            return Response({'error': 'Seuls les propriétaires peuvent traiter les demandes.'}, status=403)

        try:
            demande = DemandeRemboursement.objects.get(id=pk, proprietaire=user)
        except DemandeRemboursement.DoesNotExist:
            return Response({'error': 'Demande non trouvée.'}, status=404)

        if demande.statut != 'en_attente':
            return Response({'error': 'Cette demande a déjà été traitée.'}, status=400)

        montant_approuve = request.data.get('montant_approuve')
        if not montant_approuve:
            return Response({'error': 'Le montant approuvé est requis.'}, status=400)

        try:
            montant_approuve = Decimal(montant_approuve)
        except:
            return Response({'error': 'Montant invalide.'}, status=400)

        if montant_approuve > demande.montant_demande:
            return Response({'error': 'Le montant approuvé ne peut pas dépasser le montant demandé.'}, status=400)

        if montant_approuve > user.solde:
            return Response({'error': 'Solde insuffisant pour ce remboursement.'}, status=400)

        # Approuver la demande
        demande.montant_approuve = montant_approuve
        demande.statut = 'approuvee'
        demande.date_traitement = timezone.now()
        demande.save()

        # Déduire du solde du propriétaire
        user.solde -= montant_approuve
        user.save()

        # Créer le remboursement
        remboursement = Remboursement.objects.create(
            demande=demande,
            montant=montant_approuve,
            reference=f"REM-{uuid.uuid4().hex[:8].upper()}"
        )

        # Notification au locataire
        Notification.objects.create(
            destinataire=demande.locataire,
            type='remboursement_approuve',
            titre='Remboursement approuvé',
            message=f"Votre remboursement de {montant_approuve} FCFA a été approuvé. Vous pouvez maintenant effectuer le retrait.",
            lien=f'/remboursements/{remboursement.id}'
        )
        notify_user(
            demande.locataire,
            'Remboursement approuvé',
            f"Votre remboursement de {montant_approuve} FCFA est prêt à être retiré.",
            {'type': 'remboursement', 'remboursement_id': str(remboursement.id)}
        )

        return Response({
            'message': 'Remboursement approuvé avec succès.',
            'remboursement_id': remboursement.id,
            'montant': montant_approuve
        }, status=200)


class RetirerRemboursementView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        if user.role != 'locataire':
            return Response({'error': 'Seuls les locataires peuvent retirer leur remboursement.'}, status=403)

        try:
            remboursement = Remboursement.objects.get(id=pk, demande__locataire=user)
        except Remboursement.DoesNotExist:
            return Response({'error': 'Remboursement non trouvé.'}, status=404)

        if remboursement.statut != 'effectue':
            return Response({'error': 'Ce remboursement a déjà été retiré.'}, status=400)

        # Simuler le retrait (comme pour le propriétaire)
        # Ici vous pouvez appeler une simulation de payout ou simplement marquer comme retiré
        remboursement.statut = 'effectue'
        remboursement.save()

        # Notification au propriétaire
        Notification.objects.create(
            destinataire=remboursement.demande.proprietaire,
            type='remboursement_retire',
            titre='Remboursement retiré',
            message=f"Le locataire {remboursement.demande.locataire.get_full_name()} a retiré son remboursement de {remboursement.montant} FCFA.",
            lien=f'/remboursements/{remboursement.id}'
        )
        notify_user(
            remboursement.demande.proprietaire,
            'Remboursement retiré',
            f"Le locataire a retiré son remboursement de {remboursement.montant} FCFA.",
            {'type': 'remboursement_retire', 'remboursement_id': str(remboursement.id)}
        )

        return Response({
            'message': 'Retrait effectué avec succès.',
            'remboursement_id': remboursement.id
        }, status=200)


class ListePaiementsAvecRemboursementView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role != 'locataire':
            return Response({'error': 'Accès réservé aux locataires.'}, status=403)

        paiements = Paiement.objects.filter(
            locataire=user,
            type_paiement='avance',
            statut='valide'
        ).order_by('-date_paiement')

        serializer = PaiementSerializer(paiements, many=True)
        return Response(serializer.data)
