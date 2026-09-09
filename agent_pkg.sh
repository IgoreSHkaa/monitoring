#!/bin/sh
<<<<<<< HEAD

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
=======
>>>>>>> 6c41c11 (fix)

CACHE_DIR="${CACHE_DIR:-/var/lib/zabbix}"
CACHE="$CACHE_DIR/pkg_cache.txt"
CUR="${CUR:-/tmp/pkg_curr.txt}"

STATUS_FILE="/var/lib/dpkg/status"
if [ ! -f "$STATUS_FILE" ] && [ -f "/host/var/lib/dpkg/status" ]; then
    STATUS_FILE="/host/var/lib/dpkg/status"
fi

if [ ! -f "$STATUS_FILE" ]; then
    echo "ERROR: cannot find dpkg status file" >&2
    exit 1
fi

mkdir -p "$CACHE_DIR"

awk '/^Package:/{pkg=$2} /^Version:/{print pkg, $2}' "$STATUS_FILE" | sort > "$CUR"

if [ ! -s "$CACHE" ]; then
    cp "$CUR" "$CACHE"
    echo "INIT: cache created"
    exit 0
fi

CHANGED=$(awk '
NR==FNR { old[$1]=$2; next }
{
    new[$1]=$2
}
END {
    for (k in old) {
        if (!(k in new)) {
            print "REMOVED " k " " old[k]
        }
    }
    for (k in new) {
        if (!(k in old)) {
            print "ADDED " k " " new[k]
        } else if (old[k] != new[k]) {
            print "UPDATED " k " " old[k] " -> " new[k]
        }
    }
}' "$CACHE" "$CUR")

if [ -n "$CHANGED" ]; then
    cp "$CUR" "$CACHE"
    printf '%s\n' "$CHANGED"
    exit 1
else
    echo "OK: no package changes"
    exit 0
fi
