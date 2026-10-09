#!/bin/bash
# install.sh — installe la commande goldo dans /usr/local/bin
#
# Depuis un clone du dépôt :  ./install.sh
# Sans clone (dernière version publiée) :
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/manulasnier/goldo/main/install.sh)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPO_HTTPS="https://github.com/manulasnier/goldo.git"
RAW_URL="https://raw.githubusercontent.com/manulasnier/goldo/main"
BIN_DIR="/usr/local/bin"
GOLDO_DIR="/usr/local/lib/goldo"
TEMP_DIR="$(mktemp -d)"

trap 'rm -rf "$TEMP_DIR"' EXIT

die() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || die "goldo ne fonctionne que sur macOS."
[ "$(id -u)" -ne 0 ] || die "Ne pas lancer en root / sudo (le script demande sudo lui-même)."

# ==============================================================================
# Source : clone local, ou téléchargement (lancé via curl)
# ==============================================================================

SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_PATH" ] && [ -f "$(dirname "$SCRIPT_PATH")/bin/goldo" ]; then
    REPO_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
    LIB_SRC="$REPO_DIR/lib"
else
    REPO_DIR=""
    LIB_SRC="$TEMP_DIR/lib"
    mkdir -p "$LIB_SRC"
    for lib in utils check; do
        curl -fsSL "$RAW_URL/lib/$lib.sh" -o "$LIB_SRC/$lib.sh" || die "Téléchargement impossible : $RAW_URL/lib/$lib.sh"
    done
fi

source "$LIB_SRC/utils.sh"
source "$LIB_SRC/check.sh"

# Dernière version publiée (tag vX.Y.Z), sinon main
latest_tag() {
    git ls-remote --tags "$REPO_HTTPS" 2>/dev/null |
        grep -oE 'refs/tags/v[0-9]+\.[0-9]+\.[0-9]+$' |
        sed 's|refs/tags/||' |
        awk -F'[v.]' '{ printf "%05d%05d%05d\t%s\n", $2, $3, $4, $0 }' |
        sort | tail -n1 | cut -f2
}

main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║         Installation de goldo          ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"

    run_checks || die "Pré-requis manquants : installation interrompue."

    if [ -z "$REPO_DIR" ]; then
        local tag
        tag="$(latest_tag)"
        print_step "Téléchargement de goldo ${tag:-(main)}"
        download_release "$REPO_HTTPS" "$tag" "$TEMP_DIR/goldo" ||
            die "Échec du téléchargement de $REPO_HTTPS"
        REPO_DIR="$TEMP_DIR/goldo"
    fi

    local version
    version="$(tr -d '[:space:]' < "$REPO_DIR/VERSION")"
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Format de version invalide dans $REPO_DIR/VERSION"

    print_step "Installation de goldo $version"
    print_info "L'installation nécessite les droits sudo"
    sudo -v || die "Échec de l'élévation des privilèges"

    sed -e "s/^VERSION=\".*\"/VERSION=\"$version\"/" "$REPO_DIR/bin/goldo" > "$TEMP_DIR/goldo.bin"

    sudo mkdir -p "$BIN_DIR" "$GOLDO_DIR/commands" "$GOLDO_DIR/lib" || die "Échec création des répertoires"
    sudo install -m 755 "$TEMP_DIR/goldo.bin" "$BIN_DIR/goldo" || die "Échec copie du binaire"
    sudo install -m 755 "$REPO_DIR/commands/"* "$GOLDO_DIR/commands/" || die "Échec copie des commandes"
    sudo install -m 644 "$REPO_DIR/lib/"* "$GOLDO_DIR/lib/" || die "Échec copie des librairies"

    print_success "goldo $version installé : $BIN_DIR/goldo"

    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        print_warning "$BIN_DIR n'est pas dans votre PATH."
        print_info "Ajoutez-le : echo '$(path_line "$BIN_DIR")' >> $(shell_profile)"
    fi

    echo ""
    if ask_yes_no "Lancer l'installation de l'environnement maintenant (goldo install) ?" "o"; then
        GOLDO_CHECKED=1 "$BIN_DIR/goldo" install
    else
        print_info "Pour installer l'environnement : goldo install"
    fi
}

main
