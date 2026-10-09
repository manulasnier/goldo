# goldo

**goldo installe et configure un environnement de développement web local sur macOS**,
en répondant à quelques questions.

Au lieu d'installer et de régler à la main Apache, PHP, la base de données, le domaine local
et le certificat HTTPS, on lance une seule commande :

```bash
goldo install
```

À la fin, chaque projet placé dans `~/Sites/<projet>` est accessible sur
`https://dev.lo/<projet>/`.

## Ce que goldo met en place

- **Apache** (Homebrew), qui sert tous les projets du dossier `~/Sites`
- **PHP** (8.5 par défaut), avec la possibilité de choisir une version différente par projet
- **MariaDB ou MySQL**, au choix
- **Un domaine local** (`dev.lo` par défaut), qui pointe vers la machine
- **Le HTTPS local** : un certificat reconnu par le navigateur, sans alerte de sécurité

Tout passe par Homebrew, qui est installé s'il est absent.

## Installation

```bash
git clone git@github.com:manulasnier/goldo.git && \
cd goldo && \
./install.sh && \
cd .. && \
rm -rf goldo
```

L'installation ajoute la commande `goldo` au système, puis propose de lancer tout de suite
l'installation de l'environnement.

## Utilisation

### Installer l'environnement

```bash
goldo install
```

goldo pose cinq questions, chacune avec une réponse proposée par défaut :

| Question | Proposé |
|---|---|
| Dossier des projets | `~/Sites` |
| Version de PHP | `8.5` |
| Base de données | MariaDB (ou MySQL) |
| Domaine local | `dev.lo` |
| HTTPS local | oui |

Les réponses sont retenues : relancer `goldo install` les repropose, ce qui permet de changer
un réglage sans tout refaire.

### Choisir la version de PHP d'un projet

Par défaut, tous les projets tournent avec la version choisie à l'installation. Pour qu'un
projet utilise une autre version, il suffit d'un fichier `.phpver` à sa racine :

```bash
echo 7.4 > ~/Sites/vieux-projet/.phpver
```

Le changement est immédiat. Après avoir installé une nouvelle version de PHP, lancer
`goldo phpver` pour qu'Apache la prenne en compte.

### Autres commandes

| Commande | Rôle |
|---|---|
| `goldo phpver` | Prend en compte les versions de PHP installées |
| `goldo config` | Affiche les réglages de l'environnement |
| `goldo update` | Met à jour goldo |
| `goldo uninstall` | Supprime goldo (l'environnement installé reste en place) |
| `goldo -h` | Aide |

## Bon à savoir

- **Ne jamais lancer goldo avec `sudo`** : il demande le mot de passe administrateur
  lui-même quand c'est nécessaire.
- **MariaDB et MySQL ne peuvent pas cohabiter** : il faut choisir l'un des deux.
- Les fichiers de configuration modifiés sont sauvegardés avant chaque changement.
