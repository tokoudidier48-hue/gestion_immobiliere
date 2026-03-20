import os
import logging
import re
import math
from typing import List, Dict, Any, Optional
from langchain_community.llms import Ollama
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnableLambda
from langchain_core.documents import Document
from decouple import config
from django.conf import settings
from unites.models import Unite
from comptes.models import Utilisateur

logger = logging.getLogger(__name__)

# ===================================================================
# DONNÉES COMPLÈTES SUR TOUT LE BÉNIN
# ===================================================================

# TOUS LES DÉPARTEMENTS DU BÉNIN
DEPARTEMENTS = [
    'Alibori', 'Atacora', 'Atlantique', 'Borgou', 'Collines',
    'Donga', 'Littoral', 'Mono', 'Ouémé', 'Plateau', 'Zou'
]

# TOUTES LES COMMUNES DU BÉNIN (77 communes)
COMMUNES_BENIN = {
    'Alibori': ['Kandi', 'Banikoara', 'Gogounou', 'Karimama', 'Malanville', 'Ségbana'],
    'Atacora': ['Natitingou', 'Boukoumbé', 'Cobly', 'Kérou', 'Kouandé', 'Matéri', 'Péhunco', 'Tanguiéta', 'Toucountouna'],
    'Atlantique': ['Allada', 'Abomey-Calavi', 'Kpomassè', 'Ouidah', 'Sô-Ava', 'Toffo', 'Tori-Bossito', 'Zè'],
    'Borgou': ['Parakou', 'Bembéréké', 'Kalalé', 'N\'Dali', 'Nikki', 'Pérèrè', 'Sinendé', 'Tchaourou'],
    'Collines': ['Dassa-Zoumé', 'Bantè', 'Glazoué', 'Ouèssè', 'Savalou', 'Savè'],
    'Donga': ['Djougou', 'Bassila', 'Copargo', 'Ouaké'],
    'Littoral': ['Cotonou'],
    'Mono': ['Lokossa', 'Athiémé', 'Bopa', 'Comè', 'Grand-Popo', 'Houéyogbé'],
    'Ouémé': ['Porto-Novo', 'Adjarra', 'Adjohoun', 'Aguégués', 'Akpro-Missérété', 'Avrankou', 'Bonou', 'Dangbo', 'Sèmè-Kpodji'],
    'Plateau': ['Pobè', 'Adja-Ouèrè', 'Ifangni', 'Kétou', 'Sakété'],
    'Zou': ['Abomey', 'Agbangnizoun', 'Bohicon', 'Cové', 'Djidja', 'Ouinhi', 'Za-Kpota', 'Zagnanado', 'Zogbodomey']
}

# TOUS LES QUARTIERS CONNUS
QUARTIERS_BENIN = {
    'cotonou': ['haie vive', 'fidjrossè', 'cadjehoun', 'akpakpa', 'ganhi', 'gbegamey', 'jéricho', 'vossa', 'agla', 'enzo', 'sainte cécile', 'dantokpa', 'missebo', 'ahouansori', 'agontikon', 'dodomè', 'kpankpan', 'gbèdjromèdé', 'zongo', 'midombo', 'houénoussou', 'gbègo', 'finagnon'],
    'porto-novo': ['ouando', 'dowa', 'tokpa', 'houinmè', 'ayelawadjè', 'agbokou', 'dokè', 'kpota', 'lac', 'gbéto', 'dékin', 'hounva', 'agblangandan', 'sèdjè', 'hounlè', 'agondokpoé'],
    'parakou': ['camp goro', 'zonkon', 'kossarou', 'banikanni', 'arafat', 'tribu', 'mora', 'guéma', 'baka', 'gourou', 'kémon', 'maro', 'tchatchadakou', 'albarika', 'amadou', 'ansèkou', 'dépôt', 'kpondérou'],
    'abomey-calavi': ['zoca', 'houéyiho', 'akassato', 'godomey', 'togoudo', 'zopah', 'ahouansori', 'agori', 'togba', 'léma', 'kpota', 'dèkoungbé', 'zanmè', 'tounga', 'gbédagba', 'hêvié', 'sèmè'],
    'kandi': ['gansosso', 'bantè', 'bagou', 'angara', 'kandi-gare', 'monsey', 'bensekou', 'sanson', 'tampégré', 'wèrè', 'yanriman'],
    'natitingou': ['wèrè', 'tchirimina', 'tanti', 'pèporo', 'koussouwèrè', 'yimpissé', 'kotopounga', 'tayakou', 'koundri', 'bérékoussou', 'tiédou', 'porga'],
    'lokossa': ['agolo', 'hounsa', 'kpinnou', 'sahouè', 'zounguè', 'gbozoumè', 'dékanmè', 'houin', 'lokossa-centre', 'agame', 'zoumon', 'tchikpondé'],
    'ouidah': ['avlékété', 'pahou', 'savi', 'zoungbodji', 'kpassé', 'acron', 'adjido', 'houakpé', 'gbozoumè', 'togbin', 'agoué', 'djègbadji'],
    'djougou': ['kolokondé', 'bariénou', 'kilir', 'kpartao', 'ouworo', 'sèrou', 'tapoga', 'baka', 'djougou-ii', 'dassari', 'pélébina', 'gbahou'],
    'bohicon': ['agongon', 'gnonkon', 'kinzonmè', 'lèma', 'sodohomè', 'zobé', 'dèkanmè', 'ahouanzou', 'gnidjazoun', 'saklo', 'zounzonmè'],
    'abomey': ['agbokpa', 'détcha', 'gbégo', 'hounli', 'kinnoukpkon', 'vidoli', 'zobé', 'zounzonmè', 'ahouagon', 'dakodonou', 'goho', 'hinvi']
}

# INFOS SUR LES COMMUNES
INFOS_COMMUNES = {
    'kandi': {'departement': 'Alibori', 'description': 'Kandi est une ville du nord Bénin, chef-lieu du département de l\'Alibori.', 'activites': 'Agriculture, élevage, commerce'},
    'natitingou': {'departement': 'Atacora', 'description': 'Natitingou est la capitale de l\'Atacora, au pied de la chaîne de l\'Atacora.', 'activites': 'Tourisme, agriculture, artisanat'},
    'parakou': {'departement': 'Borgou', 'description': 'Parakou est la plus grande ville du nord Bénin, important carrefour commercial.', 'activites': 'Commerce, transport, artisanat'},
    'cotonou': {'departement': 'Littoral', 'description': 'Cotonou est la capitale économique du Bénin et sa plus grande ville.', 'activites': 'Commerce, services, transport, industrie'},
    'porto-novo': {'departement': 'Ouémé', 'description': 'Porto-Novo est la capitale officielle du Bénin, riche en histoire et culture.', 'activites': 'Administration, culture, commerce'},
    'lokossa': {'departement': 'Mono', 'description': 'Lokossa est la capitale du département du Mono, ville calme et accueillante.', 'activites': 'Administration, commerce, agriculture'},
    'ouidah': {'departement': 'Atlantique', 'description': 'Ouidah est une ville historique, berceau de la culture vodoun.', 'activites': 'Tourisme, culture, pêche'},
    'abomey-calavi': {'departement': 'Atlantique', 'description': 'Abomey-Calavi abrite la plus grande université du Bénin.', 'activites': 'Éducation, commerce, services'},
    'djougou': {'departement': 'Donga', 'description': 'Djougou est une ville cosmopolite du centre-nord.', 'activites': 'Commerce, agriculture, élevage'},
    'bohicon': {'departement': 'Zou', 'description': 'Bohicon est une ville commerçante proche d\'Abomey.', 'activites': 'Commerce, transport, artisanat'},
    'abomey': {'departement': 'Zou', 'description': 'Abomey est l\'ancienne capitale du royaume du Dahomey.', 'activites': 'Tourisme culturel, artisanat'}
}

# Dictionnaire des types d'unités
TYPES_UNITES = {
    r'appartement|appartements|appart': {
        'code': 'appartement', 
        'display': 'Appartement',
        'description': 'Un appartement est un logement indépendant avec plusieurs pièces (salon, chambres, cuisine, salle de bain). Idéal pour les familles ou les couples.'
    },
    r'chambre salon sanitaire|chambres salon sanitaire|chambre sanitaire|chambres sanitaire|cs sanitaire': {
        'code': 'chambre_salon_sanitaire', 
        'display': 'Chambre salon sanitaire',
        'description': 'Une chambre salon sanitaire comprend une chambre, un salon et des sanitaires (douche et WC) privés. Idéal pour les étudiants ou les célibataires.'
    },
    r'chambre salon ordinaire|chambres salon ordinaire|chambre ordinaire|chambres ordinaire|cs ordinaire': {
        'code': 'chambre_salon_ordinaire', 
        'display': 'Chambre salon ordinaire',
        'description': 'Une chambre salon ordinaire comprend une chambre et un salon, mais les sanitaires sont souvent partagés. Idéal pour petits budgets.'
    },
    r'deux chambres sanitaire|2 chambres sanitaire': {
        'code': 'deux_chambres_sanitaire', 
        'display': 'Deux chambres sanitaire',
        'description': 'Deux chambres avec sanitaires privés. Parfait pour deux colocataires.'
    },
    r'deux chambres ordinaire|2 chambres ordinaire': {
        'code': 'deux_chambres_ordinaire', 
        'display': 'Deux chambres ordinaire',
        'description': 'Deux chambres avec sanitaires partagés. Idéal pour colocataires à petit budget.'
    },
    r'entrée coucher sanitaire|entree coucher sanitaire|entrées coucher sanitaire|entrees coucher sanitaire|ec sanitaire': {
        'code': 'entree_coucher_sanitaire', 
        'display': 'Entrée coucher sanitaire',
        'description': "Une entrée coucher sanitaire est un petit logement composé d'une pièce principale et de sanitaires privés. Idéal pour une personne."
    },
    r'entrée coucher ordinaire|entree coucher ordinaire|entrées coucher ordinaire|entrees coucher ordinaire|ec ordinaire': {
        'code': 'entree_coucher_ordinaire', 
        'display': 'Entrée coucher ordinaire',
        'description': "Une entrée coucher ordinaire est un petit logement composé d'une pièce principale avec sanitaires partagés. Pour petits budgets."
    },
    r'boutique|boutiques': {
        'code': 'boutique', 
        'display': 'Boutique',
        'description': 'Local commercial pour activités professionnelles (commerce, bureau, atelier).'
    },
    r'studio|studios': {
        'code': 'studio', 
        'display': 'Studio',
        'description': 'Un studio est un petit logement tout-en-un avec pièce principale, coin cuisine et salle d\'eau. Idéal pour les étudiants ou célibataires.'
    },
}

# FAQ complète
FAQ = {
    'demande': {
        'mots': ['demande', 'comment faire une demande', 'envoyer demande', 'postuler'],
        'reponse': "Pour faire une demande de logement :\n\n1. Connectez-vous à votre compte\n2. Trouvez le logement qui vous intéresse\n3. Cliquez sur le bouton 'Envoyer une demande'\n4. Le propriétaire sera notifié et pourra accepter ou refuser votre demande\n5. Vous recevrez une notification de sa réponse"
    },
    'paiement': {
        'mots': ['paiement', 'payer', 'mode de paiement', 'comment payer'],
        'reponse': "Les paiements sur LoyaSmart se font via :\n\n💰 **MTN MoMo** : rapide et sécurisé\n💰 **Moov Money** : disponible partout\n💰 **Celtis** : alternative fiable\n💰 **Espèces** : possible après accord avec le propriétaire"
    },
    'avance': {
        'mots': ['avance', 'avances', 'c\'est quoi les avances'],
        'reponse': "Les avances sont le nombre de mois de loyer à payer à l'entrée dans le logement.\n\n📌 Généralement, on demande 3 mois d'avance\n📌 La somme totale à l'entrée = (loyer × nombre d'avances) + caution"
    },
    'caution': {
        'mots': ['caution', 'c\'est quoi la caution'],
        'reponse': "La caution est une somme d'argent versée au propriétaire pour couvrir d'éventuels dégâts dans le logement.\n\n🔒 Elle est restituée à la fin du bail si le logement est en bon état"
    },
    'contact': {
        'mots': ['contacter', 'contact propriétaire', 'joindre'],
        'reponse': "Pour contacter un propriétaire :\n\n📞 Son numéro est affiché dans les détails du logement\n💬 Vous pouvez lui envoyer un message via la messagerie intégrée"
    },
    'colocataire': {
        'mots': ['colocataire', 'colocation', 'trouver coloc'],
        'reponse': "Pour trouver un colocataire :\n\n👥 Sur la page du logement, cliquez sur 'Chercher un colocataire'\n📝 Remplissez le formulaire\n✅ Votre annonce sera visible par d'autres locataires"
    },
    'compte': {
        'mots': ['compte', 'problème compte', 'réinitialiser mot de passe'],
        'reponse': "Gestion de votre compte :\n\n🔐 **Mot de passe oublié** : Cliquez sur 'Mot de passe oublié'\n✏️ **Modifier profil** : Allez dans Profil > Modifier le profil"
    },
    'loysmart': {
        'mots': ['loysmart', 'c\'est quoi', 'application'],
        'reponse': "LoyaSmart est une application de gestion locative au Bénin qui permet :\n\n🏠 **Aux locataires** : trouver un logement facilement partout au Bénin\n👔 **Aux propriétaires** : gérer leurs biens et locataires\n🤖 **À Loya** : mon assistant IA pour vous guider"
    },
    'inscription': {
        'mots': ['inscrire', 'inscription', 'créer compte'],
        'reponse': "Pour vous inscrire sur LoyaSmart :\n\n1. Cliquez sur 'S'inscrire'\n2. Choisissez votre rôle : Locataire ou Propriétaire\n3. Remplissez vos informations"
    }
}

# Informations sur le Bénin
INFO_BENIN = {
    'capitale': 'Porto-Novo',
    'plus_grande_ville': 'Cotonou',
    'population': '~13 millions',
    'langues': 'Français (officiel), Fon, Yoruba, Bariba, Dendi, etc.',
    'departements': DEPARTEMENTS,
    'villes_principales': ['Cotonou', 'Porto-Novo', 'Parakou', 'Abomey-Calavi', 'Kandi', 'Natitingou', 'Lokossa']
}

# Villes avec coordonnées
VILLES_COORDONNEES = {
    'cotonou': {'lat': 6.3667, 'lon': 2.4333, 'departement': 'Littoral'},
    'porto-novo': {'lat': 6.4833, 'lon': 2.6167, 'departement': 'Ouémé'},
    'parakou': {'lat': 9.8833, 'lon': 2.6167, 'departement': 'Borgou'},
    'abomey-calavi': {'lat': 6.4489, 'lon': 2.3556, 'departement': 'Atlantique'},
    'kandi': {'lat': 11.1333, 'lon': 2.9333, 'departement': 'Alibori'},
    'natitingou': {'lat': 10.3000, 'lon': 1.3667, 'departement': 'Atacora'},
    'lokossa': {'lat': 6.6333, 'lon': 1.7167, 'departement': 'Mono'},
    'ouidah': {'lat': 6.3667, 'lon': 2.0833, 'departement': 'Atlantique'},
    'djougou': {'lat': 9.7000, 'lon': 1.6667, 'departement': 'Donga'},
    'bohicon': {'lat': 7.2000, 'lon': 2.0667, 'departement': 'Zou'},
    'abomey': {'lat': 7.1833, 'lon': 1.9833, 'departement': 'Zou'},
}

# Lieux célèbres
LIEUX_CELEBRES = {
    'aeroport de cotonou': {'lat': 6.3535, 'lon': 2.3844, 'ville': 'cotonou'},
    'aéroport de cotonou': {'lat': 6.3535, 'lon': 2.3844, 'ville': 'cotonou'},
    'port autonome de cotonou': {'lat': 6.3500, 'lon': 2.4333, 'ville': 'cotonou'},
    'universite d\'abomey-calavi': {'lat': 6.4489, 'lon': 2.3556, 'ville': 'abomey-calavi'},
    'université d\'abomey-calavi': {'lat': 6.4489, 'lon': 2.3556, 'ville': 'abomey-calavi'},
    'universite de parakou': {'lat': 9.8833, 'lon': 2.6167, 'ville': 'parakou'},
    'université de parakou': {'lat': 9.8833, 'lon': 2.6167, 'ville': 'parakou'},
    'marche dantokpa': {'lat': 6.3667, 'lon': 2.4333, 'ville': 'cotonou'},
    'marché dantokpa': {'lat': 6.3667, 'lon': 2.4333, 'ville': 'cotonou'},
    'ganhi': {'lat': 6.3667, 'lon': 2.4333, 'ville': 'cotonou'},
}

class RAGChatbot:
    """
    Chatbot intelligent - Version ULTIME avec TOUTES les conversations
    """
    
    def __init__(self, user: Utilisateur):
        self.user = user
        self.conversation_id = f"user_{user.id}"
        self.vectorstore = None
        self.chain = None
        self.chat_history = []
        self._derniers_resultats = []
        self._contexte = {
            'lieu_travail': None,
            'coords_travail': None,
            'dernier_type_recherche': None,
            'derniere_ville': None,
            'dernier_budget': None,
            'nom_utilisateur': None,
            'a_salué': False
        }
        
        self._init_llm()
        self._load_or_create_vectorstore()
        self._create_chain()
        logger.info("✅ RAGChatbot ULTIME initialisé")
    
    def _init_llm(self):
        try:
            self.llm = Ollama(
                model="llama3.2:3b",
                temperature=0.7,
                top_p=0.9,
                num_ctx=4096,
                verbose=False
            )
            logger.info("✅ Modèle LLaMA 3 chargé")
        except Exception as e:
            logger.error(f"❌ Erreur chargement modèle: {e}")
            raise
    
    def _load_or_create_vectorstore(self):
        from pathlib import Path
        vectorstore_path = Path(settings.BASE_DIR) / 'data' / 'vectorstore'
        vectorstore_path.mkdir(parents=True, exist_ok=True)
        
        embeddings = HuggingFaceEmbeddings(
            model_name="all-MiniLM-L6-v2",
            model_kwargs={'device': 'cpu'},
            encode_kwargs={'normalize_embeddings': True}
        )
        
        index_file = vectorstore_path / 'index.faiss'
        if index_file.exists():
            self.vectorstore = FAISS.load_local(
                str(vectorstore_path), 
                embeddings,
                allow_dangerous_deserialization=True
            )
            logger.info("✅ Base vectorielle chargée")
        else:
            self._create_vectorstore(embeddings, vectorstore_path)
    
    def _create_vectorstore(self, embeddings, path):
        documents = []
        
        unites = Unite.objects.filter(statut='libre')
        logger.info(f"📊 {unites.count()} logements disponibles")
        
        for unite in unites:
            doc = self._unite_to_document(unite)
            documents.append(doc)
        
        for ville, infos in INFOS_COMMUNES.items():
            doc = Document(
                page_content=f"Ville: {ville}\nDescription: {infos['description']}\nActivités: {infos['activites']}",
                metadata={"type": "ville", "ville": ville}
            )
            documents.append(doc)
        
        for key, faq in FAQ.items():
            doc = Document(
                page_content=f"Question: {key}\nRéponse: {faq['reponse']}",
                metadata={"type": "faq", "mots": faq['mots']}
            )
            documents.append(doc)
        
        benin_doc = Document(
            page_content=f"Bénin: Capitale: {INFO_BENIN['capitale']}, Plus grande ville: {INFO_BENIN['plus_grande_ville']}, Population: {INFO_BENIN['population']}, Langues: {INFO_BENIN['langues']}, Départements: {', '.join(INFO_BENIN['departements'])}",
            metadata={"type": "benin"}
        )
        documents.append(benin_doc)
        
        for pattern, type_info in TYPES_UNITES.items():
            doc = Document(
                page_content=f"Type de logement: {type_info['display']}\nDescription: {type_info['description']}",
                metadata={"type": "type_logement", "nom": type_info['display']}
            )
            documents.append(doc)
        
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
        chunks = text_splitter.split_documents(documents)
        logger.info(f"📚 {len(chunks)} chunks créés")
        
        self.vectorstore = FAISS.from_documents(chunks, embeddings)
        self.vectorstore.save_local(str(path))
        logger.info("✅ Base vectorielle créée")
    
    def _unite_to_document(self, unite) -> Document:
        prepaye_str = "avec prépayé" if unite.prepaye else "sans prépayé"
        garage_str = "avec garage" if unite.garage else "sans garage"
        
        contenu = f"""
Type: {unite.get_type_unite_display()}
Nom: {unite.nom}
Adresse: {unite.adresse}
Ville: {unite.ville}
Prix: {unite.loyer} FCFA/mois
Avance: {unite.nombre_avances} mois
Caution: {unite.prix_caution} FCFA
Prépayé: {"Oui" if unite.prepaye else "Non"}
Douche: {unite.get_type_douche_display()}
Garage: {"Oui" if unite.garage else "Non"}
Contact: {unite.contact_proprietaire}
"""
        metadata = {
            "type": "logement",
            "unite_id": unite.id,
            "ville": unite.ville.lower(),
            "prix": float(unite.loyer),
            "type_code": unite.type_unite,
            "type_display": unite.get_type_unite_display(),
        }
        return Document(page_content=contenu, metadata=metadata)
    
    def _trouver_ville(self, texte: str) -> str:
        texte = texte.lower()
        for ville in VILLES_COORDONNEES.keys():
            if ville in texte:
                return ville
        return 'cotonou'
    
    def _trouver_lieu_travail(self, message: str) -> Optional[Dict]:
        message_lower = message.lower()
        for lieu, coords in LIEUX_CELEBRES.items():
            if lieu in message_lower:
                return {'nom': lieu, 'coords': {'lat': coords['lat'], 'lon': coords['lon']}, 'ville': coords['ville']}
        for ville in VILLES_COORDONNEES.keys():
            if ville in message_lower:
                return {'nom': ville, 'coords': {'lat': VILLES_COORDONNEES[ville]['lat'], 'lon': VILLES_COORDONNEES[ville]['lon']}, 'ville': ville}
        return None
    
    def _extraire_quartier(self, adresse: str) -> str:
        adresse_lower = adresse.lower()
        for ville, quartiers in QUARTIERS_BENIN.items():
            for quartier in quartiers:
                if quartier in adresse_lower:
                    return quartier
        return "quartier inconnu"
    
    def _calculer_distance(self, coords1: Dict, coords2: Dict) -> Optional[float]:
        if coords1 and coords2:
            lat1, lon1 = coords1['lat'], coords1['lon']
            lat2, lon2 = coords2['lat'], coords2['lon']
            R = 6371
            dlat = math.radians(lat2 - lat1)
            dlon = math.radians(lon2 - lon1)
            a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
            c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
            return round(R * c, 1)
        return None
    
    def _extraire_criteres_avances(self, message: str) -> Dict[str, Any]:
        message = message.lower()
        criteres = {
            "type": None, "type_code": None, "type_display": None,
            "ville": None, "quartier": None, "budget": None,
            "lieu_travail": None, "coords_travail": None,
            "est_demande_numero": False, "est_salutation": False,
            "est_presentation": False, "est_remerciement": False,
            "est_aurevoir": False, "est_aide": False,
            "est_question_benin": False, "est_question_type": False,
            "est_question_ville": False, "est_faq": False,
            "est_recherche": False, "est_lieu_travail": False,
            "est_demande_distance": False
        }
        
        # Détection des salutations
        if any(mot in message for mot in ['bonjour', 'salut', 'hello', 'coucou', 'bjr', 'slt']):
            criteres["est_salutation"] = True
            return criteres
        
        # Détection des présentations (TRÈS IMPORTANT)
        patterns_presentation = [
            r'(?:je\s+(?:suis|m\'appelle|m appelle|me\s+nomme|c\'est)\s+)([a-z]+(?:\s+[a-z]+)*)',
            r'(?:moi\s+c\'est|moi\s+je\s+suis|appelle-moi)\s+([a-z]+(?:\s+[a-z]+)*)',
            r'^([a-z]+(?:\s+[a-z]+)*)\s*$'  # Juste un nom
        ]
        
        for pattern in patterns_presentation:
            match = re.search(pattern, message)
            if match and len(message.split()) <= 4 and not any(mot in message for mot in ['cherche', 'logement', 'chambre']):
                criteres["est_presentation"] = True
                criteres["nom"] = match.group(1).strip()
                return criteres
        
        # Détection des remerciements
        if any(mot in message for mot in ['merci', 'thanks', 'thank you', 'merci beaucoup']):
            criteres["est_remerciement"] = True
            return criteres
        
        # Détection des au revoir
        if any(mot in message for mot in ['au revoir', 'bye', 'à bientôt', 'a bientot', 'ciao']):
            criteres["est_aurevoir"] = True
            return criteres
        
        # Détection des demandes d'aide
        if any(mot in message for mot in ['aide', 'help', 'que sais-tu', 'peux-tu', 'comment ça marche']):
            criteres["est_aide"] = True
            return criteres
        
        # Détection des questions sur le Bénin
        if ('bénin' in message or 'benin' in message) and not any(mot in message for mot in ['logement', 'chambre']):
            criteres["est_question_benin"] = True
            return criteres
        
        # Détection des questions sur les types
        if any(mot in message for mot in ['type', 'types', 'c\'est quoi', 'différence', 'signifie', 'qu\'est-ce']):
            for pattern, type_info in TYPES_UNITES.items():
                if re.search(pattern, message) or type_info['display'].lower() in message:
                    criteres["est_question_type"] = True
                    criteres["type_display"] = type_info['display']
                    criteres["type_description"] = type_info['description']
                    return criteres
        
        # Détection des questions sur les villes
        if any(mot in message for mot in ['ville', 'villes', 'parle-moi', 'décris', 'raconte']):
            for ville in VILLES_COORDONNEES.keys():
                if ville in message:
                    criteres["est_question_ville"] = True
                    criteres["ville"] = ville
                    return criteres
        
        # Détection FAQ
        for key, faq in FAQ.items():
            for mot in faq['mots']:
                if mot in message:
                    criteres["est_faq"] = True
                    criteres["faq_key"] = key
                    criteres["faq_reponse"] = faq['reponse']
                    return criteres
        
        # Demande de numéro
        if message.strip().isdigit():
            criteres["est_demande_numero"] = True
            criteres["numero"] = int(message)
            return criteres
        
        # Lieu de travail
        lieu_travail = self._trouver_lieu_travail(message)
        if lieu_travail:
            criteres["est_lieu_travail"] = True
            criteres["lieu_travail"] = lieu_travail['nom']
            criteres["coords_travail"] = lieu_travail['coords']
            if lieu_travail.get('ville'):
                criteres["ville"] = lieu_travail['ville']
            return criteres
        
        # Recherche de logement
        mots_recherche = ['cherche', 'trouve', 'veux', 'logement', 'chambre', 'appartement', 
                         'studio', 'boutique', 'location', 'louer', 'disponible']
        if any(mot in message for mot in mots_recherche):
            criteres["est_recherche"] = True
        
        # Distance
        mots_distance = ['distance', 'distances', 'proche', 'près', 'km', 'loin']
        if any(mot in message for mot in mots_distance):
            criteres["est_demande_distance"] = True
        
        # Type d'unité
        for pattern, type_info in TYPES_UNITES.items():
            if re.search(pattern, message):
                criteres["type"] = pattern
                criteres["type_code"] = type_info['code']
                criteres["type_display"] = type_info['display']
                criteres["est_recherche"] = True
                break
        
        # Ville
        if not criteres.get("ville"):
            for ville in VILLES_COORDONNEES.keys():
                if ville in message:
                    criteres["ville"] = ville
                    criteres["est_recherche"] = True
                    break
        
        # Budget
        budget_match = re.search(r'(\d+)\s*(?:f|fcfa|cfa)?', message)
        if budget_match:
            criteres["budget"] = int(budget_match.group(1))
            criteres["est_recherche"] = True
        
        return criteres
    
    def _rechercher_unites_avancee(self, criteres: Dict[str, Any]) -> List[Unite]:
        queryset = Unite.objects.filter(statut='libre')
        if criteres.get("type_code"):
            queryset = queryset.filter(type_unite=criteres["type_code"])
        if criteres.get("ville"):
            queryset = queryset.filter(ville__icontains=criteres["ville"])
        if criteres.get("budget"):
            queryset = queryset.filter(loyer__lte=criteres["budget"])
        return list(queryset[:10])
    
    def _formater_resultats_avances(self, unites: List[Unite], criteres: Dict[str, Any]) -> str:
        if not unites:
            if criteres.get("type_display"):
                return f"😕 Désolé, je n'ai trouvé aucun **{criteres['type_display']}** correspondant à vos critères."
            elif criteres.get("ville"):
                return f"😕 Désolé, je n'ai trouvé aucun logement à **{criteres['ville'].capitalize()}**."
            return "😕 Désolé, aucun logement trouvé."
        
        unites_avec_distances = []
        for unite in unites:
            distance = None
            if criteres.get("coords_travail"):
                ville_base = self._trouver_ville(unite.ville)
                coords_unite = VILLES_COORDONNEES.get(ville_base)
                if coords_unite:
                    distance = self._calculer_distance(criteres["coords_travail"], coords_unite)
            unites_avec_distances.append((unite, distance))
        
        if criteres.get("coords_travail"):
            unites_avec_distances.sort(key=lambda x: x[1] if x[1] is not None else float('inf'))
        
        nom_utilisateur = self._contexte.get('nom_utilisateur', '')
        prefixe = f"{nom_utilisateur}, " if nom_utilisateur else ""
        
        if criteres.get("type_display"):
            reponse = f"{prefixe}🎉 J'ai trouvé **{len(unites)} {criteres['type_display']}(s)**"
        else:
            reponse = f"{prefixe}🎉 J'ai trouvé **{len(unites)} logement(s)**"
        
        if criteres.get("ville"):
            reponse += f" à **{criteres['ville'].capitalize()}**"
        if criteres.get("budget"):
            reponse += f" avec budget **{criteres['budget']} FCFA**"
        reponse += " :\n\n"
        
        for i, (unite, distance) in enumerate(unites_avec_distances[:5], 1):
            reponse += f"**{i}. {unite.get_type_unite_display()}**\n"
            reponse += f"📍 {unite.adresse}, {unite.ville}\n"
            reponse += f"💰 **{unite.loyer} FCFA**/mois\n"
            if distance:
                reponse += f"🚗 **{distance} km** de votre travail\n"
            reponse += "\n"
        
        reponse += "**Pour les détails, envoyez le numéro** (1, 2, 3...)"
        if not criteres.get("coords_travail"):
            reponse += "\n\n📍 **Astuce** : Dites-moi où vous travaillez pour les distances !"
        return reponse
    
    def _get_details_unite(self, unite: Unite, criteres: Dict[str, Any]) -> str:
        details = f"🔍 **Détails du logement**\n\n"
        details += f"🏠 **{unite.get_type_unite_display()}** - {unite.nom}\n"
        details += f"📍 **Adresse** : {unite.adresse}, {unite.ville}\n"
        details += f"📝 **Description** : {unite.description or 'Non spécifiée'}\n\n"
        details += f"💰 **Loyer** : {unite.loyer} FCFA/mois\n"
        details += f"📌 **Avances** : {unite.nombre_avances} mois\n"
        details += f"🔒 **Caution** : {unite.prix_caution} FCFA\n"
        details += f"🔌 **Prépayé** : {'Oui' if unite.prepaye else 'Non'}\n"
        details += f"🚿 **Douche** : {unite.get_type_douche_display()}\n"
        details += f"🚗 **Garage** : {'Oui' if unite.garage else 'Non'}\n"
        details += f"📞 **Contact** : {unite.contact_proprietaire}\n\n"
        
        if criteres.get("coords_travail"):
            ville_base = self._trouver_ville(unite.ville)
            coords_unite = VILLES_COORDONNEES.get(ville_base)
            if coords_unite:
                distance = self._calculer_distance(criteres["coords_travail"], coords_unite)
                if distance:
                    details += f"🚗 **Distance de votre travail** : {distance} km\n\n"
        
        details += f"🔗 **Lien direct** : http://127.0.0.1:8000/unites/{unite.id}"
        return details
    
    def _message_bienvenue(self):
        nom = self._contexte.get('nom_utilisateur', '')
        if nom:
            return f"👋 **Bonjour {nom.capitalize()} !** Je suis Loya, votre assistant.\n\n**Que puis-je faire pour vous ?**\n- Rechercher un logement\n- Calculer des distances\n- Répondre à vos questions"
        return """👋 **Bonjour ! Je suis Loya, votre assistant.**

**🔍 Exemples :**
- "Je cherche un appartement à Cotonou"
- "Chambre salon sanitaire à 50000 F"
- "Comment faire une demande ?"
- "Je travaille à l'aéroport"

**Comment puis-je vous aider ?** 😊"""
    
    def _message_aide(self):
        return """🤖 **AIDE - Tout ce que je peux faire**

**🏠 Recherche**
- "Je cherche un appartement à Cotonou"
- "Chambre salon sanitaire"
- "Studio à 50000 F"

**📍 Distances**
- "Je travaille à l'aéroport"
- "Mon bureau est à Parakou"

**❓ Questions**
- "C'est quoi une chambre sanitaire ?"
- "Parle-moi de Parakou"
- "Comment payer ?"

**💬 Conversation**
- "Bonjour" / "Salut"
- "Merci" / "Au revoir"
- "Je m'appelle Didier"
- "Comment ça va ?"

**Soyez naturel, je vous comprends !**"""
    
    def _message_presentation(self, nom: str):
        self._contexte['nom_utilisateur'] = nom
        self._contexte['a_salué'] = True
        return f"👋 **Enchanté {nom.capitalize()} !** Je suis Loya, votre assistant pour trouver un logement au Bénin.\n\n**Que cherchez-vous aujourd'hui ?**"
    
    def _create_chain(self):
        def process_input(inputs):
            return self._traiter_message_intelligent(inputs["question"])
        self.chain = RunnableLambda(process_input)
        logger.info("✅ Chaîne RAG créée")
    
    def _traiter_message_intelligent(self, message: str) -> Dict[str, Any]:
        criteres = self._extraire_criteres_avances(message)
        
        # 1. Présentation
        if criteres.get("est_presentation"):
            return {"reponse": self._message_presentation(criteres['nom']), "sources": []}
        
        # 2. Salutation
        if criteres.get("est_salutation"):
            return {"reponse": self._message_bienvenue(), "sources": []}
        
        # 3. Remerciement
        if criteres.get("est_remerciement"):
            return {"reponse": "😊 **Avec plaisir !** N'hésitez pas si vous avez d'autres questions.", "sources": []}
        
        # 4. Au revoir
        if criteres.get("est_aurevoir"):
            return {"reponse": "👋 **Au revoir !** Revenez quand vous voulez, je serai là pour vous aider.", "sources": []}
        
        # 5. Aide
        if criteres.get("est_aide"):
            return {"reponse": self._message_aide(), "sources": []}
        
        # 6. Question sur le Bénin
        if criteres.get("est_question_benin"):
            return {"reponse": f"🇧🇯 **Le Bénin**\nCapitale: Porto-Novo\nPlus grande ville: Cotonou\nPopulation: 13M\nDépartements: 11\nVilles: Cotonou, Porto-Novo, Parakou, etc.\n\nOù cherchez-vous un logement ?", "sources": []}
        
        # 7. Question sur type
        if criteres.get("est_question_type"):
            return {"reponse": self._repondre_question_type(criteres['type_display'], criteres['type_description']), "sources": []}
        
        # 8. Question sur ville
        if criteres.get("est_question_ville") and criteres.get("ville") in INFOS_COMMUNES:
            infos = INFOS_COMMUNES[criteres['ville']]
            return {"reponse": f"🏙️ **{criteres['ville'].capitalize()}**\nDépartement: {infos['departement']}\n{infos['description']}\nActivités: {infos['activites']}\n\nCherchez-vous un logement ici ?", "sources": []}
        
        # 9. FAQ
        if criteres.get("est_faq"):
            return {"reponse": criteres['faq_reponse'], "sources": []}
        
        # 10. Numéro
        if criteres.get("est_demande_numero") and self._derniers_resultats:
            num = criteres["numero"] - 1
            if 0 <= num < len(self._derniers_resultats):
                return {"reponse": self._get_details_unite(self._derniers_resultats[num], criteres), "sources": []}
            return {"reponse": f"❌ Numéro invalide. Choisissez 1-{len(self._derniers_resultats)}.", "sources": []}
        
        # 11. Lieu de travail
        if criteres.get("lieu_travail") and not self._contexte['lieu_travail']:
            self._contexte['lieu_travail'] = criteres['lieu_travail']
            self._contexte['coords_travail'] = criteres['coords_travail']
            return {"reponse": f"✅ **Lieu de travail enregistré !**\n\nMaintenant, je peux calculer les distances. Que cherchez-vous ?", "sources": []}
        
        # 12. Recherche
        if criteres.get("est_recherche"):
            unites = self._rechercher_unites_avancee(criteres)
            self._derniers_resultats = unites
            if self._contexte.get('coords_travail'):
                criteres['coords_travail'] = self._contexte['coords_travail']
            return {"reponse": self._formater_resultats_avances(unites, criteres), "sources": []}
        
        # 13. Réponse par défaut
        return {"reponse": "Je n'ai pas compris. Dites 'bonjour' ou 'aide' pour commencer !", "sources": []}
    
    def repondre(self, message: str) -> Dict[str, Any]:
        try:
            message = message.strip()
            result = self._traiter_message_intelligent(message)
            self.chat_history.append({"user": message, "ia": result["reponse"]})
            return result
        except Exception as e:
            logger.error(f"❌ Erreur: {e}")
            return {"reponse": "Désolé, problème technique. Réessayez.", "sources": []}