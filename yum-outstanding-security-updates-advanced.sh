#!/bin/bash
#
# Outstanding Security Updates Sensor — PRTG SSH Script Advanced
# --------------------------------------------------------------
# Returns JSON for PRTG with one channel per severity level
# (Critical, Important, Moderate, Low) plus a Total channel.
#
# Counts distinct advisories rather than affected packages: a kernel
# advisory typically ships 6+ packages but represents one piece of
# admin work.
#
# The expensive `yum updateinfo` call is cached for the day. Cached
# JSON is reused on subsequent invocations so the sensor is cheap to
# poll at PRTG's normal interval.
#
# To apply the updates this sensor reports:
#   yum update --security
#   yum update --sec-severity=Critical --sec-severity=Important
#
# Detailed advisory list with CVEs / references is written to
# $DETAIL_FILE on each refresh — read this before approving a
# maintenance window.
#
# To force a refresh: rm /tmp/lastyumcheck

# Configuration
LASTCHECK_FILE="/tmp/lastyumcheck"
RESULT_FILE="/tmp/security-update-result.json"
RAW_FILE="/tmp/security-update-list"
DETAIL_FILE="/tmp/security-update-detail"
LOG_FILE="/tmp/security-update-check.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

emit_error() {
    local msg="$1"
    log_message "ERROR: $msg"
    cat <<EOF
{
  "prtg": {
    "error": 1,
    "text": "$msg"
  }
}
EOF
    exit 0
}

# Count distinct advisory IDs at the given severity.
# Matches column 2 of `yum updateinfo list security` output, which is
# of the form "Severity/Sec." (e.g. "Important/Sec.").
count_severity() {
    local severity="$1"
    awk -v sev="$severity" 'tolower($2) == tolower(sev) "/sec." {print $1}' \
        "$RAW_FILE" 2>/dev/null | sort -u | wc -l
}

emit_result() {
    local crit="$1" imp="$2" mod="$3" low="$4"
    local total=$((crit + imp + mod + low))
    cat <<EOF
{
  "prtg": {
    "result": [
      {
        "channel": "Critical Advisories",
        "value": $crit,
        "unit": "Count",
        "limitmode": 1,
        "limitmaxerror": 0,
        "limiterrormsg": "Critical security advisory outstanding"
      },
      {
        "channel": "Important Advisories",
        "value": $imp,
        "unit": "Count",
        "limitmode": 1,
        "limitmaxwarning": 0,
        "limitmaxerror": 9,
        "limitwarningmsg": "Important security advisories outstanding",
        "limiterrormsg": "Many important advisories outstanding"
      },
      {
        "channel": "Moderate Advisories",
        "value": $mod,
        "unit": "Count",
        "limitmode": 1,
        "limitmaxwarning": 4,
        "limitwarningmsg": "Multiple moderate advisories outstanding"
      },
      {
        "channel": "Low Advisories",
        "value": $low,
        "unit": "Count"
      },
      {
        "channel": "Total Advisories",
        "value": $total,
        "unit": "Count"
      }
    ],
    "text": "$total outstanding: $crit Critical, $imp Important, $mod Moderate, $low Low"
  }
}
EOF
}

# Determine staleness of the cache
DAYSSINCECHECK=999
if [ -f "$LASTCHECK_FILE" ]; then
    LASTCHECK=$(head -n1 "$LASTCHECK_FILE" 2>/dev/null)
    if [ -n "$LASTCHECK" ] && date -d "$LASTCHECK" +%s >/dev/null 2>&1; then
        DAYSSINCECHECK=$(( ( $(date +%s) - $(date -d "$LASTCHECK" +%s) ) / (24 * 60 * 60) ))
    fi
fi
log_message "DAYSSINCECHECK: $DAYSSINCECHECK"

# Refresh if cache is stale or result file is missing
if [ "$DAYSSINCECHECK" -gt 0 ] || [ ! -f "$RESULT_FILE" ]; then
    if ! yum updateinfo list security > "$RAW_FILE" 2>&1; then
        emit_error "yum updateinfo failed; see $RAW_FILE"
    fi

    if grep -q "Is this ok \[y/N\]:" "$RAW_FILE"; then
        emit_error "yum is waiting for input or confirmation"
    fi

    CRIT=$(count_severity "Critical")
    IMP=$(count_severity "Important")
    MOD=$(count_severity "Moderate")
    LOW=$(count_severity "Low")

    emit_result "$CRIT" "$IMP" "$MOD" "$LOW" > "$RESULT_FILE"
    date '+%Y-%m-%d %H:%M' > "$LASTCHECK_FILE"

    TOTAL=$((CRIT + IMP + MOD + LOW))
    if [ "$TOTAL" -gt 0 ]; then
        yum updateinfo list security --info > "$DETAIL_FILE" 2>&1
        log_message "Refreshed: $TOTAL advisories ($CRIT/$IMP/$MOD/$LOW), detail in $DETAIL_FILE"
    else
        log_message "Refreshed: no outstanding security advisories"
    fi
fi

cat "$RESULT_FILE"
