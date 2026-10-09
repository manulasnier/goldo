#!/bin/bash

# ==============================================================================
# Contrôle du poste : macOS, outils Xcode, Homebrew, clé SSH
# Propose l'installation des outils Xcode et de Homebrew s'ils manquent.
# Nécessite utils.sh (print_*, ask_yes_no).
# ==============================================================================

# ------------------------------------------------------------------------------
# macOS
# ------------------------------------------------------------------------------

check_macos() {
    if [ "$(uname -s)" != "Darwin" ]; then
        print_error "goldo ne fonctionne que sur macOS (système détecté : $(uname -s))."
        return 1
    fi

    print_success "macOS $(sw_vers -productVersion) ($(uname -m))"
}

# ------------------------------------------------------------------------------
# Outils de ligne de commande Xcode (git, compilateurs) — requis par Homebrew
# ------------------------------------------------------------------------------

check_clt() {
    if xcode-select -p &>/dev/null && command -v git &>/dev/null && git --version &>/dev/null; then
        print_success "Outils de ligne de commande Xcode ($(git --version))"
        return 0
    fi

    print_warning "Outils de ligne de commande Xcode absents (git, compilateurs)."
    if ! ask_yes_no "Les installer maintenant ?" "o"; then
        print_error "Requis : xcode-select --install"
        return 1
    fi

    xcode-select --install 2>/dev/null
    read -r -p "Terminez l'installation dans la fenêtre macOS, puis appuyez sur Entrée..."

    if xcode-select -p &>/dev/null && git --version &>/dev/null; then
        print_success "Outils de ligne de commande Xcode installés"
    else
        print_error "Installation non terminée : relancez xcode-select --install"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------------------------

# Charge brew dans le PATH s'il est installé mais absent du PATH
load_brew() {
    command -v brew &>/dev/null && return 0
    local b
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$b" ]; then
            eval "$("$b" shellenv)"
            return 0
        fi
    done
    return 1
}

# Ajoute brew au PATH des prochains terminaux, dans le profil du shell utilisé
add_brew_to_profile() {
    local brew_bin profile sh
    brew_bin="$(command -v brew)"
    sh="$(login_shell)"
    profile="$(shell_profile)"

    if grep -qs "brew shellenv" "$profile"; then
        return 0
    fi

    print_warning "brew n'est pas dans le PATH de vos terminaux (shell : $sh)."
    if ask_yes_no "Ajouter Homebrew à ${profile/#$HOME/~} ?" "o"; then
        mkdir -p "$(dirname "$profile")"
        if [ "$sh" = "fish" ]; then
            printf '\n# Homebrew\n%s shellenv fish | source\n' "$brew_bin" >> "$profile"
        else
            printf '\n# Homebrew\neval "$(%s shellenv)"\n' "$brew_bin" >> "$profile"
        fi
        print_success "Ajouté à ${profile/#$HOME/~} (pris en compte dans les nouveaux terminaux)"
    fi
}

check_brew() {
    local in_path=1
    command -v brew &>/dev/null || in_path=0

    if ! load_brew; then
        print_warning "Homebrew n'est pas installé."
        if ! ask_yes_no "Installer Homebrew maintenant ?" "o"; then
            print_error "Requis : https://brew.sh"
            return 1
        fi
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
            print_error "Échec de l'installation de Homebrew"
            return 1
        }
        load_brew || { print_error "Homebrew introuvable après installation"; return 1; }
        in_path=0
    fi

    [ "$in_path" -eq 1 ] || add_brew_to_profile

    if ! brew --version &>/dev/null; then
        print_error "Homebrew est installé mais ne répond pas : lancez brew doctor"
        return 1
    fi

    if [ ! -w "$(brew --prefix)" ]; then
        print_error "$(brew --prefix) n'est pas accessible en écriture pour $(id -un) : lancez brew doctor"
        return 1
    fi

    print_success "$(brew --version | head -n1) ($(brew --prefix))"
}

# ------------------------------------------------------------------------------
# Clé SSH — simple avertissement si absente
# ------------------------------------------------------------------------------

check_ssh() {
    local k
    for k in id_ed25519 id_ecdsa id_rsa; do
        if [ -f "$HOME/.ssh/$k" ] && [ -f "$HOME/.ssh/$k.pub" ]; then
            print_success "Clé SSH : $HOME/.ssh/$k.pub"
            return 0
        fi
    done

    print_warning "Aucune clé SSH dans ~/.ssh : goldo update ne pourra pas joindre le dépôt."
    print_info "Pour en créer une : ssh-keygen -t ed25519"
    return 1
}

# ------------------------------------------------------------------------------
# Tous les contrôles — code retour 1 si un pré-requis bloquant manque
# (macOS, outils Xcode, Homebrew). La clé SSH n'est pas bloquante.
# ------------------------------------------------------------------------------

run_checks() {
    print_step "macOS"
    check_macos || return 1

    print_step "Outils de ligne de commande Xcode"
    check_clt || return 1

    print_step "Homebrew"
    check_brew || return 1

    print_step "Clé SSH"
    local ssh_ok=1
    check_ssh || ssh_ok=0

    echo ""
    if [ "$ssh_ok" -eq 1 ]; then
        print_success "Poste prêt."
    else
        print_success "Poste prêt (sans clé SSH)."
    fi
}
