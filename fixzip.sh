#!/bin/bash
# Переименование ущербных имён файлов после распаковки zip-архивов
# запуск: fixzip.sh "папка, где надо поправить имена"

function rename() {
    tr '†°Ґ£§•с¶І®©™Ђђ≠а-р' 'а-еёж-нр-яЁ' <<< "$1" | sed $'s/Г\xcc\x81/о/g;s/у\xcc\x81/п/g;s/ш\xcc\x86/щ/g'   
}

function renamefile() {
    local new="$(rename "$2")"

    if [[ "$2" != "$new" ]]; then
        mv "$1/$2" "$1/$new"
        echo "$new"
    fi
}

function scan() {
    ls -1 "$1" | while read file; do
        if [ -d "$1/$file" ]; then
            scan "$1/$file"
        fi
        renamefile "$1" "$file"
    done
}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

scan "${1-${SCRIPT_DIR}}"
