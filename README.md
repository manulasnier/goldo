# goldorak-devstack

Environnement de dev local macOS (Apple Silicon) : **Apache + PHP-FPM multi-versions**.
Chaque sous-dossier de `~/Sites` tourne avec la version PHP indiquée dans son fichier `.phpver`.

```
~/Sites/
├── vieux-presta/   .phpver → 7.4
├── projet-b/       .phpver → 8.2
└── projet-c/       (pas de .phpver → version par défaut)
```

## Pré-requis

- macOS Apple Silicon, Homebrew installé dans `/opt/homebrew`
- Dossier `~/Sites`
- PHP via Homebrew, une ou plusieurs versions
- Apache Homebrew (sauf si tu utilises l'Apache natif macOS avec `-m`)

```bash
# Dossier servi
mkdir -p ~/Sites

# PHP : version courante + anciennes versions (tap shivammathur)
brew install php
brew tap shivammathur/php
brew install shivammathur/php/php@7.4 shivammathur/php/php@8.2   # selon besoins

# Apache Homebrew (inutile avec -m)
brew install httpd
```

## Installation

```bash
mkdir -p ~/bin
cp install-phpver.sh ~/bin/
chmod +x ~/bin/install-phpver.sh
xattr -d com.apple.quarantine ~/bin/install-phpver.sh 2>/dev/null   # si téléchargé

# ~/bin dans le PATH (une seule fois)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Utilisation

Toujours **sans sudo** (le script demande sudo lui-même en mode `-m`).

| Commande | Apache | Accès |
|---|---|---|
| `install-phpver.sh` | Homebrew | vhosts dont le `DocumentRoot` est `~/Sites` (ex. `dev.lo`) |
| `install-phpver.sh -l` | Homebrew | `http://localhost/<projet>/`, sans vhost ni HTTPS |
| `install-phpver.sh -m` | natif macOS | vhosts dont le `DocumentRoot` est `~/Sites` |
| `install-phpver.sh -m -l` | natif macOS | `http://localhost/<projet>/`, sans vhost ni HTTPS |

Options :

- `-m` : Apache natif macOS (`/etc/apache2`) au lieu d'Apache Homebrew — PHP reste géré par Homebrew
- `-l` : mode localhost (port 80, sans vhost ni HTTPS)
- `-n` : configure sans redémarrer les services ni lancer le test
- `-h` : aide

Version PHP par défaut : celle de la formule `php` de Homebrew (sinon la plus récente installée).

**Relancer le script** après l'installation ou la suppression d'une version PHP : il est idempotent et régénère la liste des versions.

## Choisir la version PHP d'un projet

```bash
echo 7.4 > ~/Sites/mon-projet/.phpver
```

- Pris en compte immédiatement, sans redémarrage
- Formats acceptés : `7.4`, `php7.4`, `8.2.12`…
- `.phpver` absent, vide ou version non installée → version par défaut
- Les fichiers `.phpver` ne sont pas servis par Apache (403)

## Tester

Le script teste chaque version à la fin (sauf avec `-n`) :

```
   7.4   → 7.4 ✓
   8.2   → 8.2 ✓
   none  → 8.5 ✓
==> Tout est OK.
```

Test manuel (mode `-l`) :

```bash
mkdir -p ~/Sites/_t74 ~/Sites/_tdef
echo '<?php echo PHP_VERSION;' | tee ~/Sites/_t74/v.php ~/Sites/_tdef/v.php >/dev/null
echo 7.4 > ~/Sites/_t74/.phpver
for d in _t74 _tdef; do echo "$d → $(curl -s http://localhost/$d/v.php)"; done
curl -s -o /dev/null -w ".phpver → %{http_code}\n" http://localhost/_t74/.phpver
rm -rf ~/Sites/_t74 ~/Sites/_tdef
```

Attendu : 7.4.x, puis la version par défaut, puis 403.

## Ce que le script modifie

Chaque fichier modifié est sauvegardé en `<fichier>.bak-phpver-<date>`.

| Fichier | Modification |
|---|---|
| `/opt/homebrew/etc/php/X.Y/php-fpm.d/www.conf` | socket `/opt/homebrew/var/run/php-fpm-X.Y.sock`, `pm = ondemand` |
| `httpd.conf` | active `proxy`, `proxy_fcgi`, `rewrite`, `mpm_event` (+ HTTP/2) ; désactive mod_php et `mpm_prefork` ; `User` = ton utilisateur |
| `extra/phpver.conf` | conf globale (handler par défaut, blocage des `.phpver`) |
| `extra/phpver-vhost.inc` | sélection de version par sous-dossier, inclus dans les vhosts concernés |
| `bin/phpver-map` | script qui lit `.phpver` (RewriteMap) |
| `httpd.conf` en mode `-l` | `DocumentRoot ~/Sites`, `AllowOverride All`, `Listen 80`, `ServerName localhost`, vhosts et HTTPS désactivés |

Dossier de conf Apache : `/opt/homebrew/etc/httpd` (Homebrew) ou `/etc/apache2` (natif, `-m`).

## Commandes utiles

```bash
# Redémarrer
brew services restart php@7.4          # une version PHP
brew services restart httpd            # Apache Homebrew (sans sudo !)
sudo apachectl restart                 # Apache natif

# État
brew services list
ls /opt/homebrew/var/run/php-fpm-*.sock

# Logs
tail -20 /opt/homebrew/var/log/httpd/error_log   # Apache Homebrew
tail -20 /var/log/apache2/error_log              # Apache natif
tail -20 /opt/homebrew/var/log/php-fpm.log       # PHP-FPM
```

## Pièges connus

- **Ne pas lancer Apache Homebrew avec `sudo`** : il change le propriétaire de fichiers Homebrew et crée une 2ᵉ instance. macOS autorise le port 80 sans root.
- **Après un redémarrage d'Apache**, attendre 1–2 s avant de tester (requêtes vides sinon).
- **Ne plus utiliser `sphp`** ni de `LoadModule php_module` : le script désactive mod_php.
- **Nouvelle version PHP installée** : relancer `install-phpver.sh`.
- **Un seul Apache sur le port 80** : le script arrête l'autre (Homebrew ou natif) au besoin.
