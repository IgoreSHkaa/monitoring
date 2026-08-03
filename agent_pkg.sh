#!/bin/sh
CACHE="/var/lib/zabbix/pkg_cache.txt"
CUR="/tmp/pkg_curr.txt"

awk '/^Package:/{p=$2} /^Version:/{print p, $2}' /host/var/lib/dpkg/status | sort > "$CUR"

[ -s "$CACHE" ] || { cp "$CUR" "$CACHE"; echo "OK: кэш создан"; exit 0; }

NEW=$(comm -13 "$CACHE" "$CUR" | sed 's/$/; /' | tr -d '\n')
DEL=$(comm -23 "$CACHE" "$CUR" | sed 's/$/; /' | tr -d '\n')

if [ -n "$NEW" ] || [ -n "$DEL" ]; then
    cp "$CUR" "$CACHE"
    echo "UPDATED: + $NEW - $DEL"
else
    echo "OK: No updates"
fi
