#!/bin/bash
# install.sh — installe la commande goldo dans /usr/local/bin

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

[ "$(uname -s)" = "Darwin" ] || print_error "goldo ne fonctionne que sur macOS."
[ "$(id -u)" -ne 0 ] || print_error "Ne pas lancer en root / sudo (le script demande sudo lui-même)."

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION_FILE="$REPO_DIR/VERSION"
BIN_DIR="/usr/local/bin"
GOLDO_DIR="/usr/local/lib/goldo"

get_current_version() {
    [ -f "$VERSION_FILE" ] || print_error "Fichier VERSION introuvable dans $VERSION_FILE"

    local version
    version=$(tr -d '[:space:]' < "$VERSION_FILE")
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || print_error "Format de version invalide dans $VERSION_FILE"

    echo "$version"
}

main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║         Installation de goldo          ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"

    [ -f "$REPO_DIR/bin/goldo" ] || print_error "Fichier bin/goldo non trouvé dans $REPO_DIR"

    local version
    version=$(get_current_version)
    print_info "Version $version"

    print_info "L'installation nécessite les droits sudo"
    sudo -v || print_error "Échec de l'élévation des privilèges"

    local tmp
    tmp=$(mktemp)
    sed -e "s/^VERSION=\".*\"/VERSION=\"$version\"/" "$REPO_DIR/bin/goldo" > "$tmp"

    sudo mkdir -p "$BIN_DIR" "$GOLDO_DIR/commands" "$GOLDO_DIR/lib" || print_error "Échec création des répertoires"
    sudo install -m 755 "$tmp" "$BIN_DIR/goldo" || print_error "Échec copie du binaire"
    rm -f "$tmp"
    sudo install -m 755 "$REPO_DIR/commands/"* "$GOLDO_DIR/commands/" || print_error "Échec copie des commandes"
    sudo install -m 644 "$REPO_DIR/lib/"* "$GOLDO_DIR/lib/" || print_error "Échec copie des librairies"

    print_success "goldo $version installé : $BIN_DIR/goldo"

    if ! command -v goldo &>/dev/null; then
        print_warning "$BIN_DIR n'est pas dans votre PATH."
        print_info "Ajoutez-le : echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.zshrc"
    fi

    echo ""
    read -r -p "Lancer l'installation du devstack maintenant (goldo install) ? [O/n]: " answer
    if [[ "${answer:-o}" =~ ^[OoYy] ]]; then
        "$BIN_DIR/goldo" install
    else
        print_info "Pour installer le devstack : goldo install"
    fi
}

main
