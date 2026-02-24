Gestion Immobilière

Projet de soutenance de fin d'année de licence en Informatique et Télécommunication – Application Web et Mobile pour la gestion immobilière.

Technologies utilisées

- Backend : Django, Django REST Framework  
- Frontend Mobile + Web : Flutter  
- Base de données : PostgreSQL  
- Contrôle de version : Git & GitHub  

Structure du projet

gestion_immobiliere/
│
├── backend_django/Django project (API)
├── mobile_flutter/Flutter project (Mobile + Web)
├── Gest_Immo/Python virtual env (la machine virtuelle)
├── requirements.txt/Dépendances Python
├── .gitignore
└── README.md


Fonctionnalités principales

- Gestion des utilisateurs (propriétaires, locataires)  
- Authentification JWT  
- Gestion des biens immobiliers  
- Paiements et suivi des loyers  
- Interface mobile et web responsive  

Installation et Développement

Backend Django

bash
cd backend_django
python -m venv Gest_Immo
Gest_Immo\Scripts\activate
pip install -r requirements.txt (les dépendances)
python manage.py migrate
python manage.py runserver

Flutter mobile + web 

cd mobile_flutter
flutter pub get
flutter run -d chrome   # tester sur web
flutter run -d <device> # tester sur mobile









Voici les étapes à suivre pour avoir accès au projet

Étape 0 :

Vous devrez avoir sur votre PC :

Git installé

Python 3.10+ (pour Django)

Flutter (pour le projet mobile + web)

IDE : VS Code, PyCharm, Android Studio ou autre


Étape 1 :

Cloner le projet depuis GitHub

Sur votre PC :

git clone https://github.com/tokoudidier48-hue/gestion_immobiliere.git

Cela crée un dossier gestion_immobiliere/ avec tous les fichiers du projet.

Aller dans le dossier du projet

cd gestion_immobiliere

Créer l’environnement Python pour Django

cd backend_django

python -m venv Gest_Immo        // Crée un environnement virtuel

Sur Windows
Gest_Immo\Scripts\activate

Sur Mac ou Linux
source Gest_Immo/bin/activate

Installer les dépendances Python

pip install -r requirements.txt

Maintenant Django est prêt.


Étape 2 :

Vérifier Flutter

Aller dans le dossier Flutter :

cd ../mobile_flutter

Installer les dépendances Flutter :

flutter pub get

Vérifier que Flutter est bien configuré :

flutter doctor

Vérifier les branches Git

git checkout dev

Créer une branche pour son module (feature branch) ici si tout est déjà bon chez vous pouvez choisir la partie sur laquelle vous voulez travailler : voici un exemple de ce que vous devez fait

Exemple : si vous voulez travailler sur l’authentification par exemple

si c'est cote backend_django rasurez-vous que vous etre sur le dossier backend_django et c'est sur le mobile rasurez-vous que vous etre sur le dossier mobile_flutter avant de laisser la commande ci-dessus

git checkout -b feature/authentification

Tous ses changements iront sur cette branche.

Après avoir finier de travailler sur la branche choisir vous devez fait la mis jours à projet et voici comment on le fait :

Commiter les changements tapé ces commandes :

git add .
git commit -m "Ajout module authentification"

Pousser sa branche sur GitHub avec cette commande :

git push origin feature/authentification



Pour récupérer les dernières modifications de l’autre binôme (si quelqu'un d'autre veut travailler sur le projet et veut obtenir la version finale voici les commandes qu'il doit tapée):

git checkout dev
git pull origin dev
