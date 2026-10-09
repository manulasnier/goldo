#!/bin/bash

get_current_version() {
    if [ -z "$VERSION" ]; then
        echo "Erreur : Variable VERSION non définie" >&2
        return 1
    fi

    local version="$VERSION"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Erreur : Format de version invalide ($version)" >&2
        return 1
    fi

    echo "$version"
}

get_latest_version() {
    local latest_version=$(git ls-remote --tags "$REPO_URL" 2>/dev/null | \
        grep -o 'refs/tags/v[0-9]*\.[0-9]*\.[0-9]*' | \
        sed 's|refs/tags/v||' | \
        sort_version | \
        tail -n1)

    echo "$latest_version"
}

compare_versions() {
    if [ $# -ne 2 ]; then
        echo "Usage: compare_versions <version1> <version2>" >&2
        return 2
    fi

    # Retourne 0 (true) seulement si $2 est strictement supérieure à $1
    [ "$(printf '%s\n' "$1" "$2" | sort_version | tail -n1)" = "$2" ] && [ "$1" != "$2" ]
}

# ==============================================================================
# Tri sémantique compatible Git Bash (sans sort -V)
# ==============================================================================

sort_version() {
    # Transforme X.Y.Z en X.Y.Z paddé pour un tri lexicographique correct
    # ex: 1.2.10 → 0001.0002.0010, puis tri, puis dépaddage
    awk '{
        n = split($0, a, ".")
        printf "%05d.%05d.%05d\t%s\n", a[1]+0, a[2]+0, a[3]+0, $0
    }' | sort | cut -f2
}
