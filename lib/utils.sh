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
# VALIDATION
# ==============================================================================

validate_domain() {
    [[ "$1" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$ ]]
}

validate_php_version() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+$ ]]
}
