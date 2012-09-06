#!/bin/bash
while read query; do
    curl -d "text=$(echo -n "$query" | od -t x1 -A n | tr -d "\n" | sed -E 's/ +/%/g;s/%$//g')&Decode=go" \
    "http://www.artlebedev.ru/tools/decoder/" 2>&- |
    fgrep -v '<!DOCTYPE' | xpath  '//text/text()' 2>&-
done