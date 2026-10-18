# Site de réservation pour coiffeur

Site statique (un seul fichier `index.html`) hébergeable gratuitement sur **GitHub Pages**, avec une base de données gratuite **Supabase** pour partager les rendez-vous entre les clients et le coiffeur.

## Fonctionnalités

**Côté client (`#reserver`)**
- Choix du jour (28 jours à l'avance, jours fermés grisés, jours complets indiqués)
- Choix de la prestation + suppléments (cheveux longs, shampoing, motif) avec **estimation du temps** affichée
- Seuls les créneaux assez longs pour la prestation sont proposés ; si le jour est plein, le site propose le prochain créneau libre
- Formulaire prénom + téléphone (+ précision facultative), aucun paiement en ligne
- Un **code à 6 caractères** est donné pour retrouver ou annuler le rendez-vous (`#mon-rdv`)
- Anti-abus : 2 rendez-vous à venir maximum par numéro, impossible de réserver moins d'1 h à l'avance

**Espace coiffeur (`#pro`)**
- Connexion par email + mot de passe
- Agenda vue **jour** ou **semaine**, avec heures, pauses et fermetures hachurées, ligne de l'heure actuelle
- Liste des demandes **à valider** : Accepter / Décaler / Supprimer
- Décaler : seuls les horaires libres pour la durée du rendez-vous sont proposés
- Ajout d'un rendez-vous (client au téléphone ou au comptoir) en touchant une case vide de l'agenda
- Blocage de créneaux (pause, congé, journée entière)
- Messages SMS pré-remplis (confirmation, décalage, rappel) à envoyer depuis le téléphone
- Statistiques du jour et rafraîchissement automatique toutes les minutes

## Mode démo

Si `supabaseUrl` et `supabaseKey` sont vides dans `index.html`, le site fonctionne en **mode démo** : tout est stocké dans le navigateur, avec des rendez-vous d'exemple. Mot de passe coiffeur : `demo`.
Utile pour tester, mais les clients et le coiffeur ne voient pas les mêmes données. Pour la vraie version, suivez les étapes ci-dessous.

## 1. Mettre le site sur GitHub Pages

1. Créez un dépôt public sur github.com (ex. `salon-rdv`).
2. Envoyez-y `index.html` (et ce README) : bouton **Add file → Upload files**, ou en ligne de commande :
   ```bash
   git init && git add . && git commit -m "Site de réservation"
   git branch -M main
   git remote add origin https://github.com/VOTRE-PSEUDO/salon-rdv.git
   git push -u origin main
   ```
3. Dans le dépôt : **Settings → Pages → Build and deployment**, source **Deploy from a branch**, branche `main`, dossier `/ (root)`.
4. Après une minute, le site est en ligne sur `https://VOTRE-PSEUDO.github.io/salon-rdv/`.
   - Lien client : `…/salon-rdv/`
   - Lien coiffeur : `…/salon-rdv/#pro`

## 2. Brancher la base de données Supabase (gratuit)

1. Créez un compte et un projet sur supabase.com.
2. Ouvrez **SQL Editor**, collez le contenu de `schema.sql`, cliquez **Run**.
3. Créez le compte du coiffeur : **Authentication → Users → Add user** (email + mot de passe, cochez la confirmation automatique).
4. **Désactivez les inscriptions publiques** dans les réglages d'authentification (option du type « Allow new users to sign up »). Important : tout compte connecté a accès à l'agenda.
5. Dans **Project Settings → API**, copiez l'URL du projet et la clé publique (`anon` / publishable).
6. Collez-les dans `index.html` :
   ```js
   supabaseUrl: "https://xxxx.supabase.co",
   supabaseKey: "eyJhbGciOi...",
   ```
7. Poussez la modification sur GitHub.

La clé `anon` est faite pour être publique : la sécurité repose sur les règles de `schema.sql`. Les visiteurs ne peuvent ni lire les noms et téléphones, ni modifier l'agenda ; ils passent uniquement par les fonctions de réservation, et la base refuse deux rendez-vous qui se chevauchent.

## 3. Personnaliser

Tout est en haut du `<script>` de `index.html`, dans `CONFIG` :
- `salon`, `adresse`, `telephone`
- `horaires` : plages d'ouverture par jour (0 = dimanche)
- `prestations` : nom, durée (min), prix indicatif, catégorie, suppléments autorisés ou non
- `options` : suppléments et leur durée
- `pas`, `delaiMin`, `joursMax`, `maxParTel`

Si vous changez `maxParTel`, changez aussi le `2` dans la fonction `prendre_rdv` de `schema.sql`.
