# Documentation du Projet (TP1)

Ce projet est une application Flutter réalisée dans le cadre du TP1. L'application illustre un concept de rectangles cliquables qui se divisent en deux.

## Workflow du projet

Le développement de cette application suit un workflow classique pour un projet Flutter :

1. **Point d'entrée** : L'exécution de l'application commence par le fichier principal `lib/main.dart`.
2. **Développement** : Le code source de l'interface utilisateur et de la logique se trouve dans le répertoire `lib/`.
3. **Gestion des dépendances** : Les bibliothèques externes et les assets (images, polices) sont configurés dans le fichier `pubspec.yaml`.
4. **Exécution** : Le projet peut être lancé sur un émulateur ou un appareil physique via la commande de lancement classique de Flutter.

## Classes Principales

Voici un bref aperçu des classes utilisées dans le fichier `main.dart` :

- **`AppSettings`** : Gère l'état global de l'application et les paramètres tels que l'espacement, le rayon des bordures et les couleurs.
- **`MyApp`** : Le widget racine de l'application qui configure le thème et l'écran principal.
- **`SettingsDrawer`** : Le menu latéral permettant de modifier les paramètres en temps réel.
- **`SplittableRectangle`** : Un widget interactif (avec état) qui se divise en deux rectangles plus petits lorsqu'on clique dessus.
- **`_ColorOption`** : Un petit widget utilitaire pour sélectionner des couleurs prédéfinies.

Ce document fournit un aperçu simple et global du fonctionnement et de l'organisation du code.
