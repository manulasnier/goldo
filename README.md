# goldo

Devstack local macOS en une commande : **Apache (Homebrew) + PHP-FPM + MariaDB ou MySQL**,
domaine local personnalisé et certificat **SSL** local (mkcert).

Chaque sous-dossier du DocumentRoot tourne avec la version PHP indiquée dans son fichier `.phpver`.

```
~/Sites/
├── vieux-presta/   .phpver → 7.4
├── projet-b/       .phpver → 8.2
└── projet-c/       (pas de .phpver → version par défaut)
```

## Installation de la commande `goldo`

```bash
git clone git@github.com:manulasnier/goldo.git && \
cd goldo && \
./install.sh && \
cd .. && \
rm -rf goldo
```

`install.sh` copie `goldo` dans `/usr/local/bin` (librairies dans `/usr/local/lib/goldo`),
puis propose de lancer directement `goldo install`.

## Installer le devstack : `goldo install` (ou `goldo i`)

Toujours **sans sudo** : goldo demande sudo lui-même quand c'est nécessaire
(`/etc/hosts`, autorité de certification mkcert).

Questions posées (valeur par défaut entre crochets) :

| Question | Défaut |
|---|---|
| Dossier racine des projets (DocumentRoot) | `/Users/<vous>/Sites` |
| Version de PHP | `8.5` |
| Base de données | `mariadb` (ou `mysql`) |
| Domaine local | `dev.lo` |
| Certificat SSL local | oui |

Ce que fait l'installation :

1. Installe Homebrew s'il est absent (après confirmation)
2. `brew install httpd`, PHP (`php`, `php@X.Y` ou tap `shivammathur/php`), `mariadb` ou `mysql`, `mkcert` + `nss` si SSL
3. Démarre la base (`brew services start`)
4. SSL : `mkcert -install` puis certificat `<domaine>`, `*.<domaine>`, `localhost` dans `$(brew --prefix)/etc/httpd/certs/`
5. Ajoute le domaine dans `/etc/hosts`
6. `httpd.conf` : `Listen 80`, `DocumentRoot`, `AllowOverride All`, `index.php`, modules SSL/HTTP2/rewrite
7. Génère les vhosts HTTP (et HTTPS) dans `extra/goldo.conf`
8. Configure PHP-FPM multi-versions (`goldo phpver`), redémarre PHP-FPM et Apache, teste chaque version

Résultat : `https://dev.lo/<projet>/` sert `~/Sites/<projet>/`.

Les réponses sont enregistrées dans `~/.goldo`. Relancer `goldo i` les propose par défaut :
la commande est idempotente.

Si le domaine est déjà déclaré dans un autre vhost (`httpd-vhosts.conf`, `httpd-ssl.conf`…),
goldo ne génère pas de doublon et le signale.

## Commandes

| Commande | Rôle |
|---|---|
| `goldo install`, `goldo i` | Installe / reconfigure le devstack |
| `goldo phpver`, `goldo p` | (Re)configure PHP-FPM multi-versions — à relancer après l'ajout d'une version PHP |
| `goldo config`, `goldo c` | Affiche la configuration (`goldo config reset` pour la supprimer) |
| `goldo update`, `goldo u` | Met à jour goldo (dernier tag `vX.Y.Z`) |
| `goldo version`, `goldo -v` | Version installée / dernière version |
| `goldo uninstall`, `goldo un` | Supprime la commande goldo (pas le devstack) |

### `goldo phpver`

| Commande | Apache | Accès |
|---|---|---|
| `goldo phpver` | Homebrew | vhosts dont le `DocumentRoot` est celui de goldo |
| `goldo phpver -l` | Homebrew | `http://localhost/<projet>/`, sans vhost ni HTTPS |
| `goldo phpver -m` | natif macOS | vhosts dont le `DocumentRoot` est celui de goldo |
| `goldo phpver -m -l` | natif macOS | `http://localhost/<projet>/`, sans vhost ni HTTPS |

- `-m` : Apache natif macOS (`/etc/apache2`) au lieu d'Apache Homebrew — PHP reste géré par Homebrew
- `-l` : mode localhost (port 80, sans vhost ni HTTPS)
- `-n` : configure sans redémarrer les services ni lancer le test

Version PHP par défaut : celle choisie dans `goldo install`, sinon celle de la formule `php`.

## Choisir la version PHP d'un projet

```bash
brew install shivammathur/php/php@7.4   # installer la version
goldo phpver                            # la déclarer à Apache
echo 7.4 > ~/Sites/mon-projet/.phpver
```

- Pris en compte immédiatement, sans redémarrage
- Formats acceptés : `7.4`, `php7.4`, `8.2.12`…
- `.phpver` absent, vide ou version non installée → version par défaut
- Les fichiers `.phpver` ne sont pas servis par Apache (403)

## Fichiers modifiés

Chaque fichier modifié est sauvegardé en `<fichier>.bak-goldo-<date>` ou `<fichier>.bak-phpver-<date>`.

| Fichier | Modification |
|---|---|
| `~/.goldo` | réponses de `goldo install` |
| `/etc/hosts` | `127.0.0.1 <domaine>` |
| `httpd.conf` | port 80, DocumentRoot, modules, `Include extra/goldo.conf` et `extra/phpver.conf` ; mod_php désactivé ; `User` = votre utilisateur |
| `extra/goldo.conf` | vhosts HTTP / HTTPS du domaine |
| `certs/<domaine>.pem` | certificat mkcert (hors DocumentRoot : la clé n'est jamais servie) |
| `etc/php/X.Y/php-fpm.d/www.conf` | socket `var/run/php-fpm-X.Y.sock`, `pm = ondemand` |
| `extra/phpver.conf`, `extra/phpver-vhost.inc`, `bin/phpver-map` | sélection de version PHP par sous-dossier |

Dossier de conf Apache : `$(brew --prefix)/etc/httpd`.

## Commandes utiles

```bash
brew services restart httpd            # Apache Homebrew (sans sudo !)
brew services restart php              # PHP-FPM
brew services restart mariadb          # ou mysql
brew services list
tail -20 "$(brew --prefix)/var/log/httpd/error_log"
tail -20 "$(brew --prefix)/var/log/php-fpm.log"
```

## Pièges connus

- **Ne pas lancer Apache Homebrew avec `sudo`** : il change le propriétaire de fichiers Homebrew et crée une 2ᵉ instance. macOS autorise les ports 80/443 sans root.
- **MariaDB et MySQL sont incompatibles** dans Homebrew : un seul des deux.
- **Après un redémarrage d'Apache**, attendre 1–2 s avant de tester.
- **Nouvelle version PHP installée** : relancer `goldo phpver`.
- **Un seul Apache sur le port 80** : goldo arrête l'Apache natif macOS au besoin.
