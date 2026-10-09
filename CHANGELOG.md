# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.4] - 2026-10-09

### Corrigé
- `goldo update` et `install.sh` : plus d'avertissement « refs/tags/vX.Y.Z ... is not a commit! » au téléchargement d'une version (fetch du tag au lieu d'un clone partiel)

## [0.0.3] - 2026-10-09

### Corrigé
- `goldo phpver` : le test final plantait (« URL_BASE: unbound variable ») avec le bash de macOS, la variable étant collée à un caractère UTF-8

## [0.0.2] - 2026-10-09

### Ajouté
- `goldo check` : contrôle du poste (macOS, outils de ligne de commande Xcode, Homebrew, clé SSH) avec proposition d'installation des outils Xcode et de Homebrew ; simple avertissement si aucune clé SSH
- contrôle lancé au début de `install.sh` et de `goldo install`
- `install.sh` lançable sans clone : `bash -c "$(curl -fsSL https://raw.githubusercontent.com/manulasnier/goldo/main/install.sh)"` (installe le dernier tag)

### Modifié
- Homebrew ajouté au PATH dans le profil du shell de l'utilisateur (zsh, bash, fish)
- README orienté usage

## [0.0.1] - 2026-10-09

### Ajouté
- commande `goldo` (structure pw-cli : `bin/`, `lib/`, `commands/`, `install.sh`)
- `goldo install` : devstack macOS Homebrew — Apache, PHP-FPM, MariaDB ou MySQL, domaine local (`/etc/hosts`), SSL local mkcert, vhosts dans `extra/goldo.conf`
- configuration enregistrée dans `~/.goldo`, reprise par défaut à chaque relance
- `goldo config`, `goldo update`, `goldo version`, `goldo uninstall`

### Modifié
- `install-phpver.sh` devient `goldo phpver` : DocumentRoot et version PHP par défaut lus dans `~/.goldo`, préfixe Homebrew détecté (`brew --prefix`)
