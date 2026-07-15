#!/bin/sh

DPKG_STATUS="/host/var/lib/dpkg/status"
CACHE="/var/lib/zabbix/pkg_cache.txt"
CURRENT="/tmp/zabbix_pkg_curr.txt"

if [ -f "$DPKG_STATUS" ]; then
    awk '/^Package:/ {pkg=$2} /^Version:/ {print pkg, $2}' "$DPKG_STATUS" | sort > "$CURRENT"
else
    echo "ERROR: /host/var/lib/dpkg/status not found"
    exit 1
fi

if [ ! -s "$CACHE" ]; then
    cat "$CURRENT" > "$CACHE"
    echo "OK: Cache initialized"
    exit 0
fi

UPDATES=$(comm -13 "$CACHE" "$CURRENT")

if [ -z "$UPDATES" ]; then
    cat "$CURRENT" > "$CACHE"
fi

if [ -z "$UPDATES" ]; then
    echo "OK: No updates"
else
    printf "UPDATED:\n%s\n" "$UPDATES"
fi
