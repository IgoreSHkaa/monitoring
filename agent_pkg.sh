#!/bin/sh

DPKG="/host/usr/bin/dpkg-query"
RPM="/host/usr/bin/rpm"
APK="/host/sbin/apk"

CACHE="/var/lib/zabbix/pkg_cache.txt"
CURRENT="/tmp/zabbix_pkg_curr.txt"

if [ -x "$DPKG" ]; then

    "$DPKG" -W -f='${Package} ${Version}\n' | sort > "$CURRENT"
elif [ -x "$RPM" ]; then

    "$RPM" -qa --queryformat '%{NAME} %{VERSION}-%{RELEASE}\n' | sort > "$CURRENT"
elif [ -x "$APK" ]; then

    "$APK" list --installed 2>/dev/null | awk '{print $1, $2}' | sort > "$CURRENT"
else
    echo "ERROR: OS_NOT_SUPPORTED"
    exit 1
fi

if [ ! -s "$CACHE" ]; then
    mv "$CURRENT" "$CACHE"
    echo "OK: Cache initialized"
    exit 0
fi

UPDATES=$(comm -13 "$CACHE" "$CURRENT")

mv "$CURRENT" "$CACHE"

if [ -z "$UPDATES" ]; then
    echo "OK: No updates"
else
    printf "UPDATED:\n%s" "$UPDATES"
fi
