#!/bin/bash
# Evgeny Stepanischev Aug 2012 http://bolknote.ru
# http://artpolikarpov.ru/2012/08/24/1/

PLIST=~/Library/Preferences/ByHost/com.apple.HIToolbox.*.plist
BACKUP=$(echo $PLIST).backup

function GetSection {
    /usr/libexec/PlistBuddy -c "Print :$1" $PLIST
}

function WhereUS {
    local num=0

    GetSection "$1" |
    while read -r -d} line; do
        if echo "$line" | grep -Fq U.S.; then
            echo $num
            break
        fi

        let 'num++'
    done
}

function DeleteFromSection {
    [ -n "$2" ] || return

    /usr/libexec/PlistBuddy -c "Delete :$1:$2 dict" $PLIST
}

# Смотрим, не было ли бакапа
if [ -e $BACKUP ]; then
    mv -f $BACKUP $PLIST
    echo Restored.
else
    # если не было, сохраняем исходный файл
    cp $PLIST $BACKUP

    # удаляем упоминание о раскладке US изо всех секций
    /usr/libexec/PlistBuddy -c Print $PLIST | awk '/Array {/ {print $1}' |
    while read field; do
         DeleteFromSection $field `WhereUS $field`
    done

    echo Removed.
fi

echo Try to logout.
osascript -e 'tell application "System Events" to log out'