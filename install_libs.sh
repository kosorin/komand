#!/usr/bin/bash

set -e

action="$1"
toc_path="$2"

clean=
install=

case "$action" in
i | install)
    install=1
    ;;
I | reinstall)
    clean=1
    install=1
    ;;
*)
    echo "Usage: $0 [re]install [TOC_PATH]" >&2
    exit 2
    ;;
esac

if [ -z "$toc_path" ]; then
    toc_path="$(find . -maxdepth 1 -type f -name '*.toc')"
    if [[ -z "$toc_path" || "$(echo "$toc_path" | wc -l)" -ne 1 ]]; then
        echo "Error: Missing TOC path." >&2
        exit 1
    fi
fi

install() {
    case "$1" in
    svn)
        svn checkout "$3" "$2"
        ;;
    git)
        git clone "$3" "$2"
        (cd "$2" && git config core.fileMode false)
        ;;
    esac
}

update() {
    case "$1" in
    svn)
        svn up "$2"
        ;;
    git)
        (cd "$2" && git pull)
        ;;
    esac
}

libs_dir="$(dirname "$toc_path")"

while IFS= read -r info_line; do
    if [[ "$info_line" =~ ^#\ (svn|git)::(https?://.+) ]]; then
        vcs="${BASH_REMATCH[1]//[$'\r\n']/}"
        url="${BASH_REMATCH[2]//[$'\r\n']/}"

        read -r lib_line
        if [[ "$lib_line" =~ ^Libs\\([^\\]+)\\.+\.(lua|xml) ]]; then
            name="${BASH_REMATCH[1]//[$'\r\n']/}"
            dir="$libs_dir/Libs/$name"

            if ((clean)); then
                if [ -d "$dir" ]; then
                    echo -e "\e[33mclean> $dir\e[0m"
                    rm -fr "$dir"
                fi
            fi

            if ((install)); then
                if [ -d "$dir" ]; then
                    echo -e "\e[34mupdate> $dir\e[0m"
                    update "$vcs" "$dir"
                else
                    echo -e "\e[32minstall> $dir <- $url\e[0m"
                    install "$vcs" "$dir" "$url"
                fi
            fi
        fi
    fi
done <"$toc_path"
