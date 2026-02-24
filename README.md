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
