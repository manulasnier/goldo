#!/bin/bash

# ==============================================================================
# FONCTIONS D'AFFICHAGE
# ==============================================================================

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_step() {
    echo ""
    echo -e "${BLUE}==>${NC} $1"
}

# ==============================================================================
# SAISIE
# ==============================================================================

# ask_value "Question" "défaut" nom_variable
ask_value() {
    local prompt=$1
    local default=$2
    local var_name=$3
    local input

    if [ -n "$default" ]; then
        read -r -p "$prompt [$default]: " input
    else
        read -r -p "$prompt: " input
    fi

    printf -v "$var_name" '%s' "${input:-$default}"
}

# ask_choice "Question" "défaut" nom_variable choix1 choix2...
ask_choice() {
    local prompt=$1
    local default=$2
    local var_name=$3
    shift 3
    local choices=" $* "
    local input

    while true; do
        read -r -p "$prompt ($(echo "$*" | sed 's/ /\//g')) [$default]: " input
        input=$(echo "${input:-$default}" | tr '[:upper:]' '[:lower:]')
        if [[ "$choices" == *" $input "* ]]; then
            printf -v "$var_name" '%s' "$input"
            return 0
        fi
        print_warning "Choix invalide : $input"
    done
}

# ask_yes_no "Question" "o|n" → code retour 0 si oui
ask_yes_no() {
    local prompt=$1
    local default=${2:-o}
    local input

    if [ "$default" = "o" ]; then
        read -r -p "$prompt [O/n]: " input
    else
        read -r -p "$prompt [o/N]: " input
    fi

    [[ "${input:-$default}" =~ ^[OoYy] ]]
}

# ==============================================================================
# SHELL DE L'UTILISATEUR (zsh par défaut sur macOS)
# ==============================================================================

# Shell de connexion : zsh, bash, fish...
login_shell() {
    local sh
    sh="$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{ print $2 }')"
    sh="$(basename "${sh:-${SHELL:-/bin/zsh}}")"
    echo "${sh:-zsh}"
}

# Fichier lu à l'ouverture d'un terminal, selon le shell
shell_profile() {
    case "$(login_shell)" in
        zsh)  echo "$HOME/.zprofile" ;;
        bash) echo "$HOME/.bash_profile" ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "$HOME/.profile" ;;
    esac
}

# Ligne qui ajoute un dossier au PATH, dans la syntaxe du shell
path_line() {
    if [ "$(login_shell)" = "fish" ]; then
        echo "fish_add_path $1"
    else
        echo "export PATH=\"$1:\$PATH\""
    fi
}

# ==============================================================================
# TÉLÉCHARGEMENT D'UNE VERSION
# ==============================================================================

# download_release <url du dépôt> <tag ou vide pour la branche par défaut> <dossier>
# init + fetch plutôt que « clone --depth 1 --branch <tag> » : sur un tag annoté,
# le clone affiche « warning: refs/tags/vX.Y.Z ... is not a commit! »
download_release() {
    local url=$1
    local tag=$2
    local dest=$3

    git init --quiet "$dest" &&
        git -C "$dest" fetch --quiet --depth 1 "$url" ${tag:+"refs/tags/$tag"} &&
        git -C "$dest" -c advice.detachedHead=false checkout --quiet FETCH_HEAD
}

# ==============================================================================
# VALIDATION
# ==============================================================================

validate_domain() {
    [[ "$1" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$ ]]
}

validate_php_version() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+$ ]]
}
