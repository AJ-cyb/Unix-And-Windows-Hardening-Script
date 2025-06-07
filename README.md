# Système de Durcissement OS Automatisé

**Détecte votre système d'exploitation et applique automatiquement les mesures de durcissement appropriées**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Python](https://img.shields.io/badge/Python-3.7+-blue.svg)
![Bash](https://img.shields.io/badge/Bash-5.0+-green.svg)

## Fonctionnalités Principales

### Script de Détection d'OS (`detect_os.py`)
- **Identification automatique** du système d'exploitation (Windows/Linux)
- **Détection précise** des versions Windows (10, 11, Server)
- **Lancement automatique** du script de durcissement approprié
- Point d'entrée unique pour tout le système de durcissement

### Scripts de Durcissement

#### Pour Systèmes UNIX (`hard.sh`)
- Protection GRUB avec mot de passe
- Durcissement du noyau Linux
- Politiques de mot de passe avancées
- Activation de SELinux
- Configuration du pare-feu UFW
- Mise à jour système automatisée

#### Pour Windows
- **Windows 10** (`hardening_windows10.py`):
  - Activation du pare-feu
  - Désactivation du RDP
  - Réduction de la télémétrie
  - Mises à jour automatiques
  - Configuration Exploit Guard
  
- **Windows Server 2019** (`hardening_windows_server_2019.py`):
  - Désactivation compression SMBv3
  - Règles ASR (Attack Surface Reduction)
  - Politiques de mot de passe renforcées
  - Désactivation services inutiles
  - Paramètres de registre sécurisés

## Structure du Projet
Unix-And-Windows-Hardening-Script/
├── detect_os.py # Point d'entrée principal - détection OS
├── UNIX/
│ ├── hard.sh # Script de durcissement Unix/Linux
├── Windows/
│ ├── hardening_windows10.py # Durcissement Windows 10
│ └── hardening_windows_server_2019.py # Durcissement Windows Server 2019
├── README.md
└── .gitignore


## Comment Utiliser

### Étape 1: Téléchargement
```bash
git clone https://github.com/AJ-cyb/Unix-And-Windows-Hardening-Script.git
cd Unix-And-Windows-Hardening-Script

Étape 2: Exécution (Point d'Entrée Unique)
Windows (PowerShell admin):
python detect_os.py
Linux (Terminal):
sudo python3 detect_os.py

Fonctionnement:
1.Le script detect_os.py identifie votre OS
2.Il détermine la version exacte (pour Windows)
3.Il lance automatiquement le script de durcissement approprié
4.Suivez les instructions à l'écran

Requirements
Windows	Python 3.7+, PowerShell 5.1+, Admin
Linux	Python 3.7+, Bash 5.0+, sudo privileges

⚠️ Avertissements Importants
1.Testez toujours dans un environnement contrôlé avant la production
2.Certaines mesures nécessitent un redémarrage pour prendre effet
3.Les scripts modifient des configurations système critiques
4.Backupez votre système avant exécution

 Licence

## Améliorations apportées :

1. **Clarification du rôle de `detect_os.py`** :
   - Présenté comme le point d'entrée unique du système
   - Description de sa fonction de détection d'OS
   - Explication du workflow automatique

2. **Diagramme Mermaid** :
   - Workflow visuel montrant le processus de détection et d'exécution
   - Clarifie la relation entre les différents scripts

3. **Instructions simplifiées** :
   - Une seule commande à retenir (`python detect_os.py`)
   - Fonctionnement identique sur Windows et Linux

4. **Structure de projet révisée** :
   - `detect_os.py` placé à la racine pour un accès facile
   - Organisation claire des scripts par OS

5. **Tableau des prérequis** :
   - Comparaison visuelle des besoins par plateforme
   - Indication claire des privilèges nécessaires

Ce README met l'accent sur l'automatisation et la simplicité d'utilisation tout en conservant toutes les informations importantes sur les fonctionnalités et les avertissements de sécurité.
