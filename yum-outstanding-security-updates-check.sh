#!/bin/bash
#
# Outstanding Security Updates Sensor
# -----------------------------------
# Reports the number of distinct outstanding security advisories
# (Critical / Important / Moderate) on a RHEL-family system
# (RHEL, AlmaLinux, Rocky, CentOS, Amazon Linux 2/2023).
#
# Output (single line on stdout): returncode:value:message
#   0  OK
#   1  WARNING
#   2  System Error (e.g. yum waiting for input)
#   3  Protocol Error
#   4  Content Error
#
# The expensive `yum updateinfo` query is cached in $LASTYUMCHECK_FILE
# and only refreshed when the cached date is older than today, so the
# sensor itself is cheap to poll frequently.
#
# To actually apply the updates this sensor reports:
#   yum update --security                 # all severities
#   yum update --sec-severity=Important   # one severity
#   yum update --sec-severity=Critical --sec-severity=Important
#
# The detailed advisory list (CVEs, references, package set per
# advisory) is written to $SECURITY_UPDATE_DETAIL_FILE on each refresh
# and is the file to read before approving a maintenance window.

# Configuration
LASTYUMCHECK_FILE="/tmp/lastyumcheck"
SECURITY_UPDATE_LIST_FILE="/tmp/security-update-list"
SECURITY_UPDATE_DETAIL_FILE="/tmp/security-update-detail"
LOG_FILE="/tmp/security-update-check.log"

# Helpers
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

reset_lastyumcheck() {
    echo "1970-01-01 00:00" > "$LASTYUMCHECK_FILE"
    echo "9999" >> "$LASTYUMCHECK_FILE"
}

# Validate the cache file
if [ ! -f "$LASTYUMCHECK_FILE" ]; then
    reset_lastyumcheck
fi

YUMCHECKLC=$(wc -l < "$LASTYUMCHECK_FILE")
if [ "$YUMCHECKLC" != 2 ]; then
    reset_lastyumcheck
fi

DATECHECK=$(head -n1 "$LASTYUMCHECK_FILE" | grep -c "-")
if [ "$DATECHECK" != 1 ]; then
    reset_lastyumcheck
fi

LASTCHECK=$(head -n1 "$LASTYUMCHECK_FILE")
DAYSSINCECHECK=$(( ( $(date +%s) - $(date -d "$LASTCHECK" +%s) ) / (24 * 60 * 60) ))
log_message "DAYSSINCECHECK: $DAYSSINCECHECK"

if [ "$DAYSSINCECHECK" -gt 0 ]; then
    date '+%Y-%m-%d %H:%M' > "$LASTYUMCHECK_FILE"
    yum updateinfo list security > "$SECURITY_UPDATE_LIST_FILE" 2>&1

    # Defensive check: if yum somehow ended up prompting (stale lock,
    # GPG key import, repo re-signing, etc.) bail so we don't report
    # a false zero.
    if grep -q "Is this ok \[y/N\]:" "$SECURITY_UPDATE_LIST_FILE"; then
        echo "2:0:Yum is waiting for input or confirmation."
        exit 1
    fi

    # Count distinct advisory IDs rather than affected packages: a
    # single advisory often ships several packages (a kernel update is
    # typically 6+), and counting packages overstates the work an
    # admin actually needs to do. The grep is case-insensitive to
    # tolerate distros that lowercase severity labels.
    SECURITY_UPDATE_COUNT=$(grep -iE "Critical|Important|Moderate" "$SECURITY_UPDATE_LIST_FILE" \
        | awk '{print $1}' | sort -u | wc -l)

    echo "$SECURITY_UPDATE_COUNT" >> "$LASTYUMCHECK_FILE"
    echo "0:$SECURITY_UPDATE_COUNT:$SECURITY_UPDATE_COUNT Outstanding Security Updates"

    if [ "$SECURITY_UPDATE_COUNT" -gt 0 ]; then
        yum updateinfo list security --info > "$SECURITY_UPDATE_DETAIL_FILE" 2>&1
        log_message "Detail written to $SECURITY_UPDATE_DETAIL_FILE"
    fi
else
    OUTSTANDING=$(tail -n1 "$LASTYUMCHECK_FILE")
    echo "0:$OUTSTANDING:$OUTSTANDING Outstanding Security Updates"
fi
