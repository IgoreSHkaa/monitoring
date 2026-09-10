#!/bin/sh

CACHE_DIR="${CACHE_DIR:-/var/lib/zabbix}"
CACHE="$CACHE_DIR/pkg_cache.txt"
CUR="${CUR:-$CACHE_DIR/pkg_curr.txt}"

STATUS_FILE="/var/lib/dpkg/status"
if [ ! -f "$STATUS_FILE" ] && [ -f "/host/var/lib/dpkg/status" ]; then
    STATUS_FILE="/host/var/lib/dpkg/status"
fi

if [ ! -f "$STATUS_FILE" ]; then
    echo "ERROR: cannot find dpkg status file" >&2
    exit 1
fi

if ! mkdir -p "$CACHE_DIR"; then
    echo "ERROR: cannot create cache directory: $CACHE_DIR" >&2
    exit 1
fi

trap 'rm -f "$CUR"' EXIT

if ! awk '/^Package:/{pkg=$2} /^Version:/{print pkg, $2}' "$STATUS_FILE" | sort > "$CUR"; then
    echo "ERROR: cannot read package status" >&2
    exit 1
fi

if [ ! -s "$CACHE" ]; then
    if ! cp "$CUR" "$CACHE"; then
        echo "ERROR: cannot create package cache" >&2
        exit 1
    fi
    echo "INIT: cache created"
    exit 0
fi

CHANGED=$(awk '
NR==FNR { old[$1]=$2; next }
{
    new[$1]=$2
}
END {
    for (pkg in old) {
        if (!(pkg in new)) {
            print "REMOVED " pkg " " old[pkg]
        }
    }
    for (pkg in new) {
        if (!(pkg in old)) {
            print "ADDED " pkg " " new[pkg]
        } else if (old[pkg] != new[pkg]) {
            print "UPDATED " pkg " " old[pkg] " -> " new[pkg]
        }
    }
}' "$CACHE" "$CUR" | sort)

if [ -n "$CHANGED" ]; then
    if ! cp "$CUR" "$CACHE"; then
        echo "ERROR: cannot update package cache" >&2
        exit 1
    fi
    printf '%s\n' "$CHANGED"
else
    echo "OK: no package changes"
fi

exit 0
